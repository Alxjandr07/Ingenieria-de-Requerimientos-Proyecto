package ec.edu.uteq.sgroas.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;

class EmailServiceTest {

    private EmailService service;

    @BeforeEach
    void setUp() {
        service = new EmailService();
    }

    @Test
    void configuradoSinHostDebeSerFalse() {
        ReflectionTestUtils.setField(service, "host", null);

        assertFalse(service.configurado());
    }

    @Test
    void configuradoConHostEnBlancoDebeSerFalse() {
        ReflectionTestUtils.setField(service, "host", "   ");

        assertFalse(service.configurado());
    }

    @Test
    void configuradoConHostDebeSerTrue() {
        ReflectionTestUtils.setField(service, "host", "smtp.sgroas.com");

        assertTrue(service.configurado());
    }

    @Test
    void modoConsolaNoDebeLanzarAlEnviarCodigos() {
        ReflectionTestUtils.setField(service, "host", "");

        assertDoesNotThrow(() -> service.enviarCodigoVerificacion(
                "carlos@sgroas.com", "Carlos Mendoza", "123456"));
        assertDoesNotThrow(() -> service.enviarCodigoRestablecimiento(
                "carlos@sgroas.com", "654321"));
    }

    @Test
    void envioConSmtpSinServidorDebeLanzarIllegalState() {
        ReflectionTestUtils.setField(service, "host", "127.0.0.1");
        ReflectionTestUtils.setField(service, "port", 25);
        ReflectionTestUtils.setField(service, "username", "");
        ReflectionTestUtils.setField(service, "password", "");

        assertThrows(IllegalStateException.class,
                () -> service.enviarCodigoVerificacion(
                        "carlos@sgroas.com", "Carlos Mendoza", "123456"));
    }

    @Test
    void envioConSmtpYCredencialesSinServidorDebeLanzarIllegalState() {
        ReflectionTestUtils.setField(service, "host", "127.0.0.1");
        ReflectionTestUtils.setField(service, "port", 25);
        ReflectionTestUtils.setField(service, "username", "smtp-user");
        ReflectionTestUtils.setField(service, "password", "smtp-pass");

        assertThrows(IllegalStateException.class,
                () -> service.enviarCodigoRestablecimiento(
                        "carlos@sgroas.com", "654321"));
    }
}