package ec.edu.uteq.sgroas.controller;

import ec.edu.uteq.sgroas.dto.AuthResponse;
import ec.edu.uteq.sgroas.dto.EmailRequest;
import ec.edu.uteq.sgroas.dto.LoginRequest;
import ec.edu.uteq.sgroas.dto.RefreshTokenRequest;
import ec.edu.uteq.sgroas.dto.RestablecerContrasenaRequest;
import ec.edu.uteq.sgroas.dto.SesionResponse;
import ec.edu.uteq.sgroas.dto.VerificarEmailRequest;
import ec.edu.uteq.sgroas.entity.Usuario;
import ec.edu.uteq.sgroas.repository.UsuarioRepository;
import ec.edu.uteq.sgroas.security.JwtService;
import ec.edu.uteq.sgroas.security.LoginRateLimiter;
import ec.edu.uteq.sgroas.service.AuthService;
import ec.edu.uteq.sgroas.service.TokenService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;

import java.time.Duration;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final LoginRateLimiter loginRateLimiter;
    private final JwtService jwtService;
    private final TokenService tokenService;
    private final UsuarioRepository usuarioRepository;

    @Value("${app.cookie.secure:false}")
    private boolean cookieSecure;

    @Value("${app.jwt.refresh-expiration-ms:604800000}")
    private long refreshExpirationMs;

    @GetMapping("/me")
    public ResponseEntity<SesionResponse> me(
            @CookieValue(name = "access_token", required = false) String accessTokenCookie,
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader
    ) {
        String token = accessTokenCookie;
        if ((token == null || token.isBlank()) && authorizationHeader != null
                && authorizationHeader.startsWith("Bearer ")) {
            token = authorizationHeader.substring(7);
        }
        if (token == null || token.isBlank() || tokenService.accessTokenEnBlacklist(token)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        String email = jwtService.extraerEmail(token);
        if (email == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        Usuario usuario = usuarioRepository.findByEmail(email)
                .filter(Usuario::getActivo)
                .orElse(null);
        if (usuario == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok(new SesionResponse(
                usuario.getNombre(),
                usuario.getEmail(),
                usuario.getRol().name(),
                jwtService.getExpirationMs()
        ));
    }

    /*
     * No existe registro publico: los usuarios los crea el ADMIN desde el
     * modulo Usuarios (POST /api/usuarios) y ahi mismo se les envia por
     * correo el codigo de activacion que se confirma en /verify-email.
     *
     * Los tokens viajan SOLO en cookies HttpOnly (access_token +
     * refresh_token). El cuerpo devuelve el perfil de sesion sin JWT.
     */

    @PostMapping("/login")
    public ResponseEntity<?> login(
            @Valid @RequestBody LoginRequest request,
            HttpServletRequest httpRequest
    ) {
        String ip = httpRequest.getRemoteAddr();
        if (loginRateLimiter.estaBloqueado(ip)) {
            ProblemDetail detail = ProblemDetail.forStatus(HttpStatus.TOO_MANY_REQUESTS);
            detail.setTitle("Demasiadas solicitudes");
            detail.setDetail("Has superado el limite de intentos de inicio de sesion. Espera 60 segundos.");
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body(detail);
        }
        try {
            AuthResponse response = authService.login(request);
            loginRateLimiter.resetear(ip);
            return ResponseEntity.ok()
                    .header(HttpHeaders.SET_COOKIE, crearCookieAccessToken(response.accessToken()))
                    .header(HttpHeaders.SET_COOKIE, crearCookieRefreshToken(response.refreshToken()))
                    .body(aSesion(response));
        } catch (Exception e) {
            loginRateLimiter.registrarIntentoFallido(ip);
            throw e;
        }
    }

    @PostMapping("/refresh")
    public ResponseEntity<SesionResponse> refresh(
            @CookieValue(name = "refresh_token", required = false) String refreshCookie,
            @RequestBody(required = false) RefreshTokenRequest body
    ) {
        String refreshToken = refreshCookie;
        if ((refreshToken == null || refreshToken.isBlank()) && body != null) {
            refreshToken = body.refreshToken();
        }
        if (refreshToken == null || refreshToken.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        AuthResponse response = authService.refresh(new RefreshTokenRequest(refreshToken));
        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, crearCookieAccessToken(response.accessToken()))
                .header(HttpHeaders.SET_COOKIE, crearCookieRefreshToken(response.refreshToken()))
                .body(aSesion(response));
    }

    /** Confirma el codigo enviado al correo y activa la cuenta (inicia sesion). */
    @PostMapping("/verify-email")
    public ResponseEntity<SesionResponse> verificarEmail(
            @Valid @RequestBody VerificarEmailRequest request
    ) {
        AuthResponse response = authService.verificarEmail(request.email(), request.codigo());
        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, crearCookieAccessToken(response.accessToken()))
                .header(HttpHeaders.SET_COOKIE, crearCookieRefreshToken(response.refreshToken()))
                .body(aSesion(response));
    }

    /** Reenvia el codigo de verificacion (respuesta generica para no revelar cuentas). */
    @PostMapping("/resend-code")
    public ResponseEntity<Map<String, String>> reenviarCodigo(
            @Valid @RequestBody EmailRequest request
    ) {
        authService.reenviarCodigoVerificacion(request.email());
        return ResponseEntity.ok(Map.of(
                "mensaje",
                "Si el correo corresponde a una cuenta pendiente, enviamos un nuevo codigo. Revisa tambien tu carpeta de spam."
        ));
    }

    /** Solicita un codigo para restablecer la contrasena (respuesta generica). */
    @PostMapping("/forgot-password")
    public ResponseEntity<Map<String, String>> olvidarContrasena(
            @Valid @RequestBody EmailRequest request
    ) {
        authService.solicitarRestablecimiento(request.email());
        return ResponseEntity.ok(Map.of(
                "mensaje",
                "Si el correo esta registrado, enviamos un codigo para restablecer la contrasena."
        ));
    }

    /** Restablece la contrasena con el codigo recibido por correo. */
    @PostMapping("/reset-password")
    public ResponseEntity<Map<String, String>> restablecerContrasena(
            @Valid @RequestBody RestablecerContrasenaRequest request
    ) {
        authService.restablecerContrasena(request.email(), request.codigo(), request.nuevaPassword());
        return ResponseEntity.ok(Map.of(
                "mensaje", "Contrasena actualizada correctamente. Ya puedes iniciar sesion."
        ));
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(
            @CookieValue(name = "access_token", required = false) String accessTokenCookie,
            @CookieValue(name = "refresh_token", required = false) String refreshCookie,
            @RequestBody(required = false) RefreshTokenRequest body
    ) {
        String accessToken = accessTokenCookie == null ? "" : accessTokenCookie;
        String refreshToken = refreshCookie;
        if ((refreshToken == null || refreshToken.isBlank()) && body != null) {
            refreshToken = body.refreshToken();
        }
        authService.logout(accessToken,
                new RefreshTokenRequest(refreshToken == null ? "" : refreshToken));
        return ResponseEntity.noContent()
                .header(HttpHeaders.SET_COOKIE, eliminarCookieAccessToken())
                .header(HttpHeaders.SET_COOKIE, eliminarCookieRefreshToken())
                .build();
    }

    private SesionResponse aSesion(AuthResponse response) {
        return new SesionResponse(
                response.nombre(),
                response.email(),
                response.rol(),
                response.expiresIn()
        );
    }

    private String crearCookieAccessToken(String token) {
        return ResponseCookie.from("access_token", token)
                .httpOnly(true)
                .secure(cookieSecure)
                .sameSite("Strict")
                .path("/")
                .maxAge(Duration.ofHours(1))
                .build()
                .toString();
    }

    private String crearCookieRefreshToken(String token) {
        return ResponseCookie.from("refresh_token", token)
                .httpOnly(true)
                .secure(cookieSecure)
                .sameSite("Strict")
                .path("/api/auth")
                .maxAge(Duration.ofMillis(refreshExpirationMs))
                .build()
                .toString();
    }

    private String eliminarCookieAccessToken() {
        return ResponseCookie.from("access_token", "")
                .httpOnly(true)
                .secure(cookieSecure)
                .sameSite("Strict")
                .path("/")
                .maxAge(0)
                .build()
                .toString();
    }

    private String eliminarCookieRefreshToken() {
        return ResponseCookie.from("refresh_token", "")
                .httpOnly(true)
                .secure(cookieSecure)
                .sameSite("Strict")
                .path("/api/auth")
                .maxAge(0)
                .build()
                .toString();
    }
}
