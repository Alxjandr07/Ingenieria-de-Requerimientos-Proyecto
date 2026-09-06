package ec.edu.uteq.sgroas.exception;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.net.URI;
import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail manejarErroresValidacion(
            MethodArgumentNotValidException ex,
            HttpServletRequest request
    ) {
        ProblemDetail detail = ProblemDetail.forStatus(HttpStatus.UNPROCESSABLE_ENTITY);
        detail.setType(URI.create("https://sgroas.uteq.edu.ec/errors/validation"));
        detail.setTitle("Error de validacion");
        detail.setDetail("Existen campos invalidos en la solicitud");
        detail.setInstance(URI.create(request.getRequestURI()));

        Map<String, String> errores = new HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(error ->
                errores.put(error.getField(), error.getDefaultMessage())
        );
        detail.setProperty("errors", errores);

        return detail;
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ProblemDetail manejarArgumentosInvalidos(
            IllegalArgumentException ex,
            HttpServletRequest request
    ) {
        ProblemDetail detail = ProblemDetail.forStatus(HttpStatus.BAD_REQUEST);
        detail.setType(URI.create("https://sgroas.uteq.edu.ec/errors/bad-request"));
        detail.setTitle("Solicitud invalida");
        detail.setDetail(ex.getMessage());
        detail.setInstance(URI.create(request.getRequestURI()));

        return detail;
    }

    @ExceptionHandler(BadCredentialsException.class)
    public ProblemDetail manejarCredencialesInvalidas(
            BadCredentialsException ex,
            HttpServletRequest request
    ) {
        ProblemDetail detail = ProblemDetail.forStatus(HttpStatus.UNAUTHORIZED);
        detail.setType(URI.create("https://sgroas.uteq.edu.ec/errors/unauthorized"));
        detail.setTitle("Credenciales invalidas");
        detail.setDetail("El email o la contrasena son incorrectos");
        detail.setInstance(URI.create(request.getRequestURI()));

        return detail;
    }

    @ExceptionHandler(CorreoNoVerificadoException.class)
    public ProblemDetail manejarCorreoNoVerificado(
            CorreoNoVerificadoException ex,
            HttpServletRequest request
    ) {
        ProblemDetail detail = ProblemDetail.forStatus(HttpStatus.FORBIDDEN);
        detail.setType(URI.create("https://sgroas.uteq.edu.ec/errors/email-not-verified"));
        detail.setTitle("Correo sin verificar");
        detail.setDetail(ex.getMessage());
        detail.setInstance(URI.create(request.getRequestURI()));

        return detail;
    }

    /** Denegaciones de @PreAuthorize: 403, no 500 como hacia el catch-all. */
    @ExceptionHandler(org.springframework.security.access.AccessDeniedException.class)
    public ProblemDetail manejarAccesoDenegado(
            org.springframework.security.access.AccessDeniedException ex,
            HttpServletRequest request
    ) {
        ProblemDetail detail = ProblemDetail.forStatus(HttpStatus.FORBIDDEN);
        detail.setType(URI.create("https://sgroas.uteq.edu.ec/errors/forbidden"));
        detail.setTitle("Acceso denegado");
        detail.setDetail("No tiene permisos para realizar esta operacion");
        detail.setInstance(URI.create(request.getRequestURI()));

        return detail;
    }

    /** Rutas inexistentes (ej. el antiguo /api/auth/register): 404, no 500. */
    @ExceptionHandler(org.springframework.web.servlet.resource.NoResourceFoundException.class)
    public ProblemDetail manejarRutaInexistente(
            org.springframework.web.servlet.resource.NoResourceFoundException ex,
            HttpServletRequest request
    ) {
        ProblemDetail detail = ProblemDetail.forStatus(HttpStatus.NOT_FOUND);
        detail.setType(URI.create("https://sgroas.uteq.edu.ec/errors/not-found"));
        detail.setTitle("Recurso no encontrado");
        detail.setDetail("La ruta solicitada no existe");
        detail.setInstance(URI.create(request.getRequestURI()));

        return detail;
    }

    @ExceptionHandler(Exception.class)
    public ProblemDetail manejarErrorGeneral(
            Exception ex,
            HttpServletRequest request
    ) {
        ex.printStackTrace();

        ProblemDetail detail = ProblemDetail.forStatus(HttpStatus.INTERNAL_SERVER_ERROR);
        detail.setType(URI.create("https://sgroas.uteq.edu.ec/errors/internal"));
        detail.setTitle("Error interno del servidor");
        detail.setDetail(ex.getClass().getSimpleName() + ": " + ex.getMessage());
        detail.setInstance(URI.create(request.getRequestURI()));

        return detail;
    }
}
