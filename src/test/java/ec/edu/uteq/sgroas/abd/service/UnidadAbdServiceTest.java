package ec.edu.uteq.sgroas.abd.service;

import ec.edu.uteq.sgroas.abd.dto.AbdDtos;
import ec.edu.uteq.sgroas.abd.entity.Unidad;
import ec.edu.uteq.sgroas.abd.repository.UnidadRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UnidadAbdServiceTest {

    @Mock
    private UnidadRepository unidadRepository;

    @InjectMocks
    private UnidadAbdService service;

    private Unidad unidadEjemplo() {
        return Unidad.builder()
                .idUnidad(1).placa("ABC-1234").numeroDisco("001")
                .modelo("Hiace").capacidad(14).anioFabricacion(2020)
                .estado("Activo").build();
    }

    private AbdDtos.UnidadRequest requestEjemplo(String estado) {
        return new AbdDtos.UnidadRequest("ABC-1234", "001", "Hiace", 14, 2020, estado);
    }

    @Test
    void listarSinFiltrosUsaFindAll() {
        PageRequest pageable = PageRequest.of(0, 10);
        when(unidadRepository.findAll(pageable)).thenReturn(new PageImpl<>(List.of(unidadEjemplo())));

        Page<AbdDtos.UnidadResponse> page = service.listar(null, null, pageable);

        assertEquals(1, page.getTotalElements());
        verify(unidadRepository).findAll(pageable);
        verify(unidadRepository, never()).buscarConFiltros(any(), any(), any());
    }

    @Test
    void listarConBlancosUsaFindAll() {
        PageRequest pageable = PageRequest.of(0, 10);
        when(unidadRepository.findAll(pageable)).thenReturn(new PageImpl<>(List.of()));

        service.listar("   ", "  ", pageable);

        verify(unidadRepository).findAll(pageable);
    }

    @Test
    void listarConFiltrosUsaBuscar() {
        PageRequest pageable = PageRequest.of(0, 10);
        when(unidadRepository.buscarConFiltros(eq("activo"), eq("abc"), any()))
                .thenReturn(new PageImpl<>(List.of(unidadEjemplo())));

        Page<AbdDtos.UnidadResponse> page = service.listar("  Activo ", " ABC ", pageable);

        assertEquals(1, page.getTotalElements());
        verify(unidadRepository).buscarConFiltros(eq("activo"), eq("abc"), any());
    }

    @Test
    void buscarPorIdOkYNoEncontrado() {
        when(unidadRepository.findById(1)).thenReturn(Optional.of(unidadEjemplo()));
        assertEquals("ABC-1234", service.buscarPorId(1).placa());

        when(unidadRepository.findById(99)).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class, () -> service.buscarPorId(99));
    }

    @Test
    void crearConEstadoNuloUsaActivoPorDefecto() {
        when(unidadRepository.existsByPlacaIgnoreCase("ABC-1234")).thenReturn(false);
        when(unidadRepository.existsByNumeroDiscoIgnoreCase("001")).thenReturn(false);
        when(unidadRepository.save(any(Unidad.class))).thenReturn(unidadEjemplo());

        AbdDtos.UnidadResponse r = service.crear(requestEjemplo(null));

        assertNotNull(r);
        verify(unidadRepository).save(any(Unidad.class));
    }

    @Test
    void crearConPlacaDuplicadaFalla() {
        when(unidadRepository.existsByPlacaIgnoreCase("ABC-1234")).thenReturn(true);

        assertThrows(IllegalArgumentException.class, () -> service.crear(requestEjemplo("Activo")));
        verify(unidadRepository, never()).save(any());
    }

    @Test
    void crearConDiscoDuplicadoFalla() {
        when(unidadRepository.existsByPlacaIgnoreCase("ABC-1234")).thenReturn(false);
        when(unidadRepository.existsByNumeroDiscoIgnoreCase("001")).thenReturn(true);

        assertThrows(IllegalArgumentException.class, () -> service.crear(requestEjemplo("Activo")));
    }

    @Test
    void actualizarSinEstadoMantieneActual() {
        Unidad actual = unidadEjemplo();
        when(unidadRepository.findById(1)).thenReturn(Optional.of(actual));
        when(unidadRepository.save(any(Unidad.class))).thenReturn(actual);

        AbdDtos.UnidadResponse r = service.actualizar(1, requestEjemplo(null));

        assertEquals("Activo", r.estado());
        verify(unidadRepository, never()).existsByPlacaIgnoreCase(any());
    }

    @Test
    void actualizarConEstadoLoCambia() {
        Unidad actual = unidadEjemplo();
        actual.setPlaca("XYZ-9999");
        actual.setNumeroDisco("009");
        when(unidadRepository.findById(1)).thenReturn(Optional.of(actual));
        when(unidadRepository.existsByPlacaIgnoreCase("ABC-1234")).thenReturn(false);
        when(unidadRepository.existsByNumeroDiscoIgnoreCase("001")).thenReturn(false);
        when(unidadRepository.save(any(Unidad.class))).thenAnswer(i -> i.getArgument(0));

        AbdDtos.UnidadResponse r = service.actualizar(1, requestEjemplo("Inactivo"));

        assertEquals("Inactivo", r.estado());
    }

    @Test
    void actualizarPlacaDuplicadaFalla() {
        Unidad actual = unidadEjemplo();
        actual.setPlaca("OTRA-0000");
        when(unidadRepository.findById(1)).thenReturn(Optional.of(actual));
        when(unidadRepository.existsByPlacaIgnoreCase("ABC-1234")).thenReturn(true);

        assertThrows(IllegalArgumentException.class, () -> service.actualizar(1, requestEjemplo("Activo")));
    }

    @Test
    void actualizarDiscoDuplicadoFalla() {
        Unidad actual = unidadEjemplo();
        actual.setNumeroDisco("009");
        when(unidadRepository.findById(1)).thenReturn(Optional.of(actual));
        when(unidadRepository.existsByNumeroDiscoIgnoreCase("001")).thenReturn(true);

        assertThrows(IllegalArgumentException.class, () -> service.actualizar(1, requestEjemplo("Activo")));
    }

    @Test
    void actualizarInexistenteFalla() {
        when(unidadRepository.findById(99)).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class, () -> service.actualizar(99, requestEjemplo("Activo")));
    }

    @Test
    void eliminarOkYNoExiste() {
        when(unidadRepository.existsById(1)).thenReturn(true);
        service.eliminar(1);
        verify(unidadRepository).deleteById(1);

        when(unidadRepository.existsById(99)).thenReturn(false);
        assertThrows(IllegalArgumentException.class, () -> service.eliminar(99));
    }
}
