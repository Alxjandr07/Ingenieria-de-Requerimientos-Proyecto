package ec.edu.uteq.sgroas.service;

import ec.edu.uteq.sgroas.dto.AsignacionRutaRequest;
import ec.edu.uteq.sgroas.dto.AsignacionRutaResponse;
import ec.edu.uteq.sgroas.entity.*;
import ec.edu.uteq.sgroas.repository.AsignacionRutaRepository;
import ec.edu.uteq.sgroas.repository.ConductorRepository;
import ec.edu.uteq.sgroas.repository.RutaRepository;
import ec.edu.uteq.sgroas.repository.VehiculoRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AsignacionRutaServiceTest {

    @Mock
    private AsignacionRutaRepository asignacionRutaRepository;

    @Mock
    private ConductorRepository conductorRepository;

    @Mock
    private VehiculoRepository vehiculoRepository;

    @Mock
    private RutaRepository rutaRepository;

    @InjectMocks
    private AsignacionRutaService asignacionRutaService;

    private Conductor conductorEjemplo() {
        return Conductor.builder()
                .id(1L).nombres("Carlos").apellidos("Mendoza")
                .cedula("1200000001").numeroLicencia("LIC-001")
                .tipoLicencia("E").fechaVencimientoLicencia(LocalDate.now().plusDays(30))
                .telefono("0988888888").email("carlos@sgroas.com")
                .estado(EstadoConductor.ACTIVO).activo(true)
                .creadoEn(Instant.now()).actualizadoEn(Instant.now())
                .build();
    }

    private Vehiculo vehiculoEjemplo() {
        return Vehiculo.builder()
                .id(1L).placa("GTU-001").marca("Toyota").modelo("Hiace")
                .anio(2020).capacidadPasajeros(14).numeroMotor("MOT")
                .numeroChasis("CHAS").color("Blanco")
                .estado(EstadoVehiculo.ACTIVO).activo(true)
                .creadoEn(Instant.now()).actualizadoEn(Instant.now())
                .build();
    }

    private Ruta rutaEjemplo() {
        return Ruta.builder()
                .id(1L).codigo("R-001").nombre("Quito-Guayaquil")
                .origen("Quito").destino("Guayaquil").distanciaKm(420.0)
                .duracionEstimadaMin(480).estado(EstadoRuta.ACTIVA).activo(true)
                .creadoEn(Instant.now()).actualizadoEn(Instant.now())
                .build();
    }

    private AsignacionRuta asignacionEjemplo() {
        return AsignacionRuta.builder()
                .id(1L).conductor(conductorEjemplo()).vehiculo(vehiculoEjemplo())
                .ruta(rutaEjemplo()).fechaAsignacion(LocalDate.now())
                .fechaInicio(LocalDate.now()).fechaFin(LocalDate.now().plusDays(1))
                .estado(EstadoAsignacion.ACTIVA).activo(true)
                .creadoEn(Instant.now()).actualizadoEn(Instant.now())
                .build();
    }

    private AsignacionRutaRequest requestEjemplo() {
        return new AsignacionRutaRequest(
                1L, 1L, 1L, LocalDate.now(), LocalDate.now(),
                LocalDate.now().plusDays(1), "ACTIVA"
        );
    }

    @Test
    void listarDebeRetornarPagina() {
        PageRequest pageable = PageRequest.of(0, 10);
        when(asignacionRutaRepository.findByActivoTrue(pageable))
                .thenReturn(new PageImpl<>(List.of(asignacionEjemplo())));

        Page<AsignacionRutaResponse> pagina = asignacionRutaService.listar(pageable);

        assertEquals(1, pagina.getTotalElements());
        assertEquals("Carlos Mendoza", pagina.getContent().get(0).conductorNombre());
        assertEquals("GTU-001", pagina.getContent().get(0).vehiculoPlaca());
        assertEquals("Quito-Guayaquil", pagina.getContent().get(0).rutaNombre());
    }

    @Test
    void buscarPorIdDebeRetornarAsignacion() {
        when(asignacionRutaRepository.findWithDetalle(1L))
                .thenReturn(Optional.of(asignacionEjemplo()));

        AsignacionRutaResponse response = asignacionRutaService.buscarPorId(1L);

        assertEquals(1L, response.id());
        assertEquals("ACTIVA", response.estado());
    }

    @Test
    void buscarPorIdInexistenteDebeLanzarExcepcion() {
        when(asignacionRutaRepository.findWithDetalle(99L)).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class,
                () -> asignacionRutaService.buscarPorId(99L));
    }

    @Test
    void crearDebeGuardarYRetornar() {
        when(conductorRepository.findById(1L)).thenReturn(Optional.of(conductorEjemplo()));
        when(vehiculoRepository.findById(1L)).thenReturn(Optional.of(vehiculoEjemplo()));
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(rutaEjemplo()));
        when(asignacionRutaRepository.save(any(AsignacionRuta.class)))
                .thenReturn(asignacionEjemplo());

        AsignacionRutaResponse response = asignacionRutaService.crear(requestEjemplo());

        assertNotNull(response);
        assertEquals(1L, response.id());
        verify(asignacionRutaRepository).save(any(AsignacionRuta.class));
    }

    @Test
    void crearSinConductorDebeLanzarExcepcion() {
        when(conductorRepository.findById(1L)).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class,
                () -> asignacionRutaService.crear(requestEjemplo()));
    }

    @Test
    void crearSinVehiculoDebeLanzarExcepcion() {
        when(conductorRepository.findById(1L)).thenReturn(Optional.of(conductorEjemplo()));
        when(vehiculoRepository.findById(1L)).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class,
                () -> asignacionRutaService.crear(requestEjemplo()));
    }

    @Test
    void crearSinRutaDebeLanzarExcepcion() {
        when(conductorRepository.findById(1L)).thenReturn(Optional.of(conductorEjemplo()));
        when(vehiculoRepository.findById(1L)).thenReturn(Optional.of(vehiculoEjemplo()));
        when(rutaRepository.findById(1L)).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class,
                () -> asignacionRutaService.crear(requestEjemplo()));
    }

    @Test
    void crearConEstadoInvalidoDebeLanzarExcepcion() {
        when(conductorRepository.findById(1L)).thenReturn(Optional.of(conductorEjemplo()));
        when(vehiculoRepository.findById(1L)).thenReturn(Optional.of(vehiculoEjemplo()));
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(rutaEjemplo()));

        AsignacionRutaRequest request = new AsignacionRutaRequest(
                1L, 1L, 1L, LocalDate.now(), LocalDate.now(),
                LocalDate.now().plusDays(1), "INVALIDO"
        );

        assertThrows(IllegalArgumentException.class,
                () -> asignacionRutaService.crear(request));
    }

    @Test
    void actualizarDebeModificarYRetornar() {
        when(asignacionRutaRepository.findWithDetalle(1L))
                .thenReturn(Optional.of(asignacionEjemplo()));
        when(conductorRepository.findById(1L)).thenReturn(Optional.of(conductorEjemplo()));
        when(vehiculoRepository.findById(1L)).thenReturn(Optional.of(vehiculoEjemplo()));
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(rutaEjemplo()));
        when(asignacionRutaRepository.save(any(AsignacionRuta.class)))
                .thenReturn(asignacionEjemplo());

        AsignacionRutaResponse response = asignacionRutaService.actualizar(1L, requestEjemplo());

        assertEquals(1L, response.id());
        verify(asignacionRutaRepository).save(any(AsignacionRuta.class));
    }

    @Test
    void desactivarDebeCambiarEstado() {
        when(asignacionRutaRepository.findWithDetalle(1L))
                .thenReturn(Optional.of(asignacionEjemplo()));

        asignacionRutaService.desactivar(1L);

        verify(asignacionRutaRepository).save(argThat(a ->
                !a.getActivo() && a.getEstado() == EstadoAsignacion.CANCELADA));
    }
}
