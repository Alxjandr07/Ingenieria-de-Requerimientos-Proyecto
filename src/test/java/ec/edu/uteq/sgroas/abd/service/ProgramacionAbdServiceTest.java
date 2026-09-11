package ec.edu.uteq.sgroas.abd.service;

import ec.edu.uteq.sgroas.abd.dto.AbdDtos;
import ec.edu.uteq.sgroas.abd.entity.*;
import ec.edu.uteq.sgroas.abd.repository.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ProgramacionAbdServiceTest {

    @Mock
    private ProgramacionRepository programacionRepository;
    @Mock
    private RutaAbdRepository rutaAbdRepository;
    @Mock
    private UnidadRepository unidadRepository;
    @Mock
    private ConductorAbdRepository conductorAbdRepository;

    @InjectMocks
    private ProgramacionAbdService service;

    private Ciudad ciudad() {
        return Ciudad.builder().idCiudad(1).nombre("Quevedo").build();
    }

    private Terminal terminal(int id, String nombre) {
        return Terminal.builder().idTerminal(id).nombre(nombre).ciudad(ciudad()).build();
    }

    private RutaAbd ruta() {
        return RutaAbd.builder().idRuta(1)
                .terminalOrigen(terminal(1, "T1")).terminalDestino(terminal(2, "T2"))
                .precioPasaje(new BigDecimal("2.50")).build();
    }

    private Unidad unidad(String estado) {
        return Unidad.builder().idUnidad(1).placa("ABC-1234").numeroDisco("001")
                .modelo("Hiace").capacidad(14).anioFabricacion(2020).estado(estado).build();
    }

    private ConductorAbd conductor() {
        return ConductorAbd.builder().idConductor(1).cedula("1200000001")
                .nombres("Carlos").licencia("E").telefono("0988888888").build();
    }

    private Programacion programacion() {
        return Programacion.builder().idProgramacion(1).fecha(LocalDate.now())
                .horaSalida(LocalTime.of(8, 0)).horaEstimadaLlegada(LocalTime.of(10, 0))
                .estado("Programado").ruta(ruta()).unidad(unidad("Activo")).conductor(conductor()).build();
    }

    private AbdDtos.ProgramacionRequest request(String estado) {
        return new AbdDtos.ProgramacionRequest(LocalDate.now(),
                LocalTime.of(8, 0), LocalTime.of(10, 0), estado, 1, 1, 1);
    }

    @Test
    void listarSinFiltrosUsaFindAll() {
        PageRequest pageable = PageRequest.of(0, 10);
        when(programacionRepository.findAll(pageable)).thenReturn(new PageImpl<>(List.of(programacion())));

        assertEquals(1, service.listar(null, null, null, null, null, pageable).getTotalElements());
        verify(programacionRepository).findAll(pageable);
    }

    @Test
    void listarIdsCeroONulosSeNormalizan() {
        PageRequest pageable = PageRequest.of(0, 10);
        when(programacionRepository.findAll(pageable)).thenReturn(new PageImpl<>(List.of()));

        service.listar("  ", 0, -1, null, null, pageable);

        verify(programacionRepository).findAll(pageable);
    }

    @Test
    void listarConFiltrosUsaBuscar() {
        PageRequest pageable = PageRequest.of(0, 10);
        when(programacionRepository.buscarConFiltros(any(), any(), any(), any(), any(), any()))
                .thenReturn(new PageImpl<>(List.of(programacion())));

        assertEquals(1, service.listar("Programado", 1, 1,
                LocalDate.now().minusDays(1), LocalDate.now(), pageable).getTotalElements());
    }

    @Test
    void crearOkConEstadoPorDefecto() {
        when(rutaAbdRepository.findById(1)).thenReturn(Optional.of(ruta()));
        when(unidadRepository.findById(1)).thenReturn(Optional.of(unidad("Activo")));
        when(conductorAbdRepository.findById(1)).thenReturn(Optional.of(conductor()));
        when(programacionRepository.save(any(Programacion.class))).thenReturn(programacion());

        assertNotNull(service.crear(request(null)));
    }

    @Test
    void crearHoraInvalidaFalla() {
        AbdDtos.ProgramacionRequest bad = new AbdDtos.ProgramacionRequest(LocalDate.now(),
                LocalTime.of(10, 0), LocalTime.of(8, 0), null, 1, 1, 1);

        assertThrows(IllegalArgumentException.class, () -> service.crear(bad));
        verify(programacionRepository, never()).save(any());
    }

    @Test
    void crearSinRutaUnidadOConductorFalla() {
        when(rutaAbdRepository.findById(1)).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class, () -> service.crear(request(null)));

        when(rutaAbdRepository.findById(1)).thenReturn(Optional.of(ruta()));
        when(unidadRepository.findById(1)).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class, () -> service.crear(request(null)));

        when(unidadRepository.findById(1)).thenReturn(Optional.of(unidad("Activo")));
        when(conductorAbdRepository.findById(1)).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class, () -> service.crear(request(null)));
    }

    @Test
    void crearConUnidadInactivaFalla() {
        when(rutaAbdRepository.findById(1)).thenReturn(Optional.of(ruta()));
        when(unidadRepository.findById(1)).thenReturn(Optional.of(unidad("Inactivo")));
        when(conductorAbdRepository.findById(1)).thenReturn(Optional.of(conductor()));

        assertThrows(IllegalStateException.class, () -> service.crear(request(null)));
    }

    @Test
    void actualizarSinEstadoMantieneYConEstadoCambia() {
        Programacion p = programacion();
        when(programacionRepository.findById(1)).thenReturn(Optional.of(p));
        when(rutaAbdRepository.findById(1)).thenReturn(Optional.of(ruta()));
        when(unidadRepository.findById(1)).thenReturn(Optional.of(unidad("Activo")));
        when(conductorAbdRepository.findById(1)).thenReturn(Optional.of(conductor()));
        when(programacionRepository.save(any(Programacion.class))).thenAnswer(i -> i.getArgument(0));

        assertEquals("Programado", service.actualizar(1, request(null)).estado());
        assertEquals("Completado", service.actualizar(1, request("Completado")).estado());
    }

    @Test
    void actualizarInexistenteYUnidadInactivaFallan() {
        when(programacionRepository.findById(99)).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class, () -> service.actualizar(99, request(null)));

        when(programacionRepository.findById(1)).thenReturn(Optional.of(programacion()));
        when(rutaAbdRepository.findById(1)).thenReturn(Optional.of(ruta()));
        when(unidadRepository.findById(1)).thenReturn(Optional.of(unidad("En Mantenimiento")));
        when(conductorAbdRepository.findById(1)).thenReturn(Optional.of(conductor()));
        assertThrows(IllegalStateException.class, () -> service.actualizar(1, request(null)));
    }

    @Test
    void eliminarOkYNoExiste() {
        when(programacionRepository.existsById(1)).thenReturn(true);
        service.eliminar(1);
        verify(programacionRepository).deleteById(1);

        when(programacionRepository.existsById(99)).thenReturn(false);
        assertThrows(IllegalArgumentException.class, () -> service.eliminar(99));
    }
}
