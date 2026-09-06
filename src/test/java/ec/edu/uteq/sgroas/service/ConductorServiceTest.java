package ec.edu.uteq.sgroas.service;

import ec.edu.uteq.sgroas.dto.ConductorRequest;
import ec.edu.uteq.sgroas.dto.ConductorResponse;
import ec.edu.uteq.sgroas.entity.Conductor;
import ec.edu.uteq.sgroas.entity.EstadoConductor;
import ec.edu.uteq.sgroas.repository.ConductorRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ConductorServiceTest {

    @Mock
    private ConductorRepository conductorRepository;

    @InjectMocks
    private ConductorService conductorService;

    private Conductor conductorBase() {
        return Conductor.builder()
                .id(1L)
                .nombres("Carlos Alberto")
                .apellidos("Mendoza Vera")
                .cedula("1200000001")
                .numeroLicencia("LIC-001-2026")
                .tipoLicencia("E")
                .fechaVencimientoLicencia(LocalDate.now().plusDays(20))
                .telefono("0988888888")
                .email("carlos.mendoza@sgroas.com")
                .estado(EstadoConductor.ACTIVO)
                .activo(true)
                .creadoEn(Instant.now())
                .actualizadoEn(Instant.now())
                .build();
    }

    private ConductorRequest requestBase() {
        return new ConductorRequest(
                "Carlos Alberto",
                "Mendoza Vera",
                "1200000001",
                "LIC-001-2026",
                "E",
                LocalDate.now().plusDays(20),
                "0988888888",
                "carlos.mendoza@sgroas.com",
                "ACTIVO"
        );
    }

    @Test
    void crearConductorCorrectamente() {
        ConductorRequest request = new ConductorRequest(
                "Carlos Alberto",
                "Mendoza Vera",
                "1200000001",
                "LIC-001-2026",
                "E",
                LocalDate.of(2026, 7, 15),
                "0988888888",
                "carlos.mendoza@sgroas.com",
                "ACTIVO"
        );

        Conductor conductorGuardado = Conductor.builder()
                .id(1L)
                .nombres("Carlos Alberto")
                .apellidos("Mendoza Vera")
                .cedula("1200000001")
                .numeroLicencia("LIC-001-2026")
                .tipoLicencia("E")
                .fechaVencimientoLicencia(LocalDate.of(2026, 7, 15))
                .telefono("0988888888")
                .email("carlos.mendoza@sgroas.com")
                .estado(EstadoConductor.ACTIVO)
                .activo(true)
                .creadoEn(Instant.now())
                .actualizadoEn(Instant.now())
                .build();

        when(conductorRepository.existsByCedula("1200000001"))
                .thenReturn(false);
        when(conductorRepository.existsByNumeroLicencia("LIC-001-2026"))
                .thenReturn(false);
        when(conductorRepository.save(any(Conductor.class)))
                .thenReturn(conductorGuardado);

        ConductorResponse response = conductorService.crear(request);

        assertNotNull(response);
        assertEquals(1L, response.id());
        assertEquals("Carlos Alberto", response.nombres());
        assertEquals("1200000001", response.cedula());
        assertEquals("ACTIVO", response.estado());
        verify(conductorRepository).save(any(Conductor.class));
    }

    @Test
    void crearConductorConCedulaDuplicadaDebeLanzarExcepcion() {
        ConductorRequest request = new ConductorRequest(
                "Carlos Alberto",
                "Mendoza Vera",
                "1200000001",
                "LIC-001-2026",
                "E",
                LocalDate.of(2026, 7, 15),
                "0988888888",
                "carlos.mendoza@sgroas.com",
                "ACTIVO"
        );

        when(conductorRepository.existsByCedula("1200000001"))
                .thenReturn(true);

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> conductorService.crear(request)
        );

        assertEquals("Ya existe un conductor con esa cedula", exception.getMessage());
        verify(conductorRepository, never()).save(any(Conductor.class));
    }

    @Test
    void buscarConductorPorIdCorrectamente() {
        Conductor conductor = Conductor.builder()
                .id(1L)
                .nombres("Carlos Alberto")
                .apellidos("Mendoza Vera")
                .cedula("1200000001")
                .numeroLicencia("LIC-001-2026")
                .tipoLicencia("E")
                .fechaVencimientoLicencia(LocalDate.now().plusDays(20))
                .telefono("0988888888")
                .email("carlos.mendoza@sgroas.com")
                .estado(EstadoConductor.ACTIVO)
                .activo(true)
                .creadoEn(Instant.now())
                .actualizadoEn(Instant.now())
                .build();

        when(conductorRepository.findById(1L))
                .thenReturn(Optional.of(conductor));

        ConductorResponse response = conductorService.buscarPorId(1L);

        assertNotNull(response);
        assertEquals(1L, response.id());
        assertEquals("Carlos Alberto", response.nombres());
        assertTrue(response.licenciaPorVencer());
    }

    @Test
    void listarSinBusquedaDebeUsarFindByActivoTrue() {
        org.springframework.data.domain.PageRequest pageable =
                org.springframework.data.domain.PageRequest.of(0, 10);
        when(conductorRepository.findByActivoTrue(pageable))
                .thenReturn(new org.springframework.data.domain.PageImpl<>(List.of(conductorBase())));

        var pagina = conductorService.listar(null, pageable);

        assertEquals(1, pagina.getTotalElements());
        verify(conductorRepository).findByActivoTrue(pageable);
        verify(conductorRepository, never()).buscarActivos(any(), any());
    }

    @Test
    void listarConBusquedaEnBlancoDebeUsarFindByActivoTrue() {
        org.springframework.data.domain.PageRequest pageable =
                org.springframework.data.domain.PageRequest.of(0, 10);
        when(conductorRepository.findByActivoTrue(pageable))
                .thenReturn(new org.springframework.data.domain.PageImpl<>(List.of(conductorBase())));

        var pagina = conductorService.listar("   ", pageable);

        assertEquals(1, pagina.getTotalElements());
        verify(conductorRepository).findByActivoTrue(pageable);
    }

    @Test
    void listarConBusquedaDebeUsarBuscarActivos() {
        org.springframework.data.domain.PageRequest pageable =
                org.springframework.data.domain.PageRequest.of(0, 10);
        when(conductorRepository.buscarActivos("carlos", pageable))
                .thenReturn(new org.springframework.data.domain.PageImpl<>(List.of(conductorBase())));

        var pagina = conductorService.listar("  Carlos ", pageable);

        assertEquals(1, pagina.getTotalElements());
        verify(conductorRepository).buscarActivos("carlos", pageable);
        verify(conductorRepository, never()).findByActivoTrue(pageable);
    }

    @Test
    void actualizarConCedulaDuplicadaDebeLanzarExcepcion() {
        when(conductorRepository.findById(1L)).thenReturn(Optional.of(conductorBase()));
        when(conductorRepository.existsByCedula("0999999999")).thenReturn(true);

        ConductorRequest request = new ConductorRequest(
                "Carlos Alberto", "Mendoza Vera", "0999999999", "LIC-001-2026",
                "E", LocalDate.now().plusDays(20), "0988888888",
                "carlos.mendoza@sgroas.com", "ACTIVO");

        assertThrows(IllegalArgumentException.class,
                () -> conductorService.actualizar(1L, request));
    }

    @Test
    void actualizarConLicenciaDuplicadaDebeLanzarExcepcion() {
        when(conductorRepository.findById(1L)).thenReturn(Optional.of(conductorBase()));
        when(conductorRepository.existsByNumeroLicencia("LIC-999-2026")).thenReturn(true);

        ConductorRequest request = new ConductorRequest(
                "Carlos Alberto", "Mendoza Vera", "1200000001", "LIC-999-2026",
                "E", LocalDate.now().plusDays(20), "0988888888",
                "carlos.mendoza@sgroas.com", "ACTIVO");

        assertThrows(IllegalArgumentException.class,
                () -> conductorService.actualizar(1L, request));
    }

    @Test
    void actualizarDebeModificarYGuardar() {
        when(conductorRepository.findById(1L)).thenReturn(Optional.of(conductorBase()));
        when(conductorRepository.save(any(Conductor.class))).thenReturn(conductorBase());

        ConductorResponse response = conductorService.actualizar(1L, requestBase());

        assertEquals(1L, response.id());
        assertEquals("1200000001", response.cedula());
        verify(conductorRepository).save(any(Conductor.class));
        verify(conductorRepository, never()).existsByCedula(any());
        verify(conductorRepository, never()).existsByNumeroLicencia(any());
    }

    @Test
    void desactivarDebeMarcarInactivo() {
        when(conductorRepository.findById(1L)).thenReturn(Optional.of(conductorBase()));

        conductorService.desactivar(1L);

        verify(conductorRepository).save(argThat(c ->
                !c.getActivo() && c.getEstado() == EstadoConductor.INACTIVO));
    }

    @Test
    void licenciaVencidaDebeMarcarLicenciaPorVencerFalse() {
        Conductor vencido = conductorBase();
        vencido.setFechaVencimientoLicencia(LocalDate.now().minusDays(5));
        when(conductorRepository.findById(1L)).thenReturn(Optional.of(vencido));

        ConductorResponse response = conductorService.buscarPorId(1L);

        assertFalse(response.licenciaPorVencer());
    }

    @Test
    void licenciaLejanaDebeMarcarLicenciaPorVencerFalse() {
        Conductor lejana = conductorBase();
        lejana.setFechaVencimientoLicencia(LocalDate.now().plusDays(60));
        when(conductorRepository.findById(1L)).thenReturn(Optional.of(lejana));

        ConductorResponse response = conductorService.buscarPorId(1L);

        assertFalse(response.licenciaPorVencer());
    }
}
