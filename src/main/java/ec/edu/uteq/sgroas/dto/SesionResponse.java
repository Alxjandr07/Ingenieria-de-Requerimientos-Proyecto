package ec.edu.uteq.sgroas.dto;

/**
 * Perfil de sesión que viaja en el cuerpo de las respuestas de
 * autenticación. No contiene ningún token: el JWT va solo en la
 * cookie HttpOnly {@code access_token} (Secure + SameSite=Strict).
 */
public record SesionResponse(
        String nombre,
        String email,
        String rol,
        Long expiresIn
) {
}
