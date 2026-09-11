package ec.edu.uteq.sgroas.abd.service;

import ec.edu.uteq.sgroas.abd.dto.AbdDtos;
import ec.edu.uteq.sgroas.abd.entity.IncidenteAbd;
import ec.edu.uteq.sgroas.abd.entity.Unidad;
import ec.edu.uteq.sgroas.abd.repository.AlertaRepository;
import ec.edu.uteq.sgroas.abd.repository.IncidenteAbdRepository;
import ec.edu.uteq.sgroas.abd.repository.UnidadRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class IncidenteAbdServiceTest {

    @Mock
    private IncidenteAbdRepository incidenteRepository;
    @Mock
    private AlertaRepository alertaRepository;
    @Mock
    private UnidadRepository unidadRepository;

    @InjectMocks
    private IncidenteAbdService service;

    private Unidad unidad() {
        return Unidad.builder().idUnidad(1).placa("ABC-1234").numeroDisco("001")
                .modelo("Hiace").capacidad(14).anioFabricacion(2020).estado("Activo").build();
    }

    private IncidenteAbd incidente(String nivel) {
        return IncidenteAbd.builder().idIncidente(1).tipo("Choque")
                .descripcion("Choque leve").nivelSugerido(nivel)
                .fechaIncidente(LocalDateTime.now()).evidencia("foto.jpg")
                .estado("Reportado").unidad(unidad()).build();
    }

    private AbdDtos.IncidenteAbdRequest request(String nivel, String evidencia, String estado) {
        return new AbdDtos.IncidenteAbdRequest("Choque", "Choque leve", nivel, evidencia, estado, 1);
    }

    @Test
    void listarSinFiltrosUsaFindAll() {
        PageRequest pageable = PageRequest.of(0, 10);
        when(incidenteRepository.findAll(pageable)).thenReturn(new PageImpl<>(List.of(incidente("BAJO"))));

        assertEquals(1, service.listar(null, "  ", null, pageable).getTotalElements());
    }

    @Test
    void listarConSearchUsaBuscar() {
        PageRequest pageable = PageRequest.of(0, 10);
        when(incidenteRepository.buscarConFiltros(any(), any(), any(), any()))
                .thenReturn(new PageImpl<>(List.of(incidente("MEDIO"))));

        assertEquals(1, service.listar("Reportado", "MEDIO", "choque", pageable).getTotalElements());
    }

    @Test
    void listarSoloEstadoUsaFindByEstado() {
        PageRequest pageable = PageRequest.of(0, 10);
        when(incidenteRepository.findByEstadoIgnoreCase(eq("reportado"), eq(pageable)))
                .thenReturn(new PageImpl<>(List.of(incidente("BAJO"))));

        assertEquals(1, service.listar("Reportado", null, null, pageable).getTotalElements());
    }

    @Test
    void listarSoloNivelUsaFindByNivel() {
        PageRequest pageable = PageRequest.of(0, 10);
        when(incidenteRepository.findByNivelSugeridoIgnoreCase(eq("alto"), eq(pageable)))
                .thenReturn(new PageImpl<>(List.of(incidente("ALTO"))));

        assertEquals(1, service.listar(null, "ALTO", null, pageable).getTotalElements());
    }

    @Test
    void crearNivelAltoGeneraAlerta() {
        when(unidadRepository.findById(1)).thenReturn(Optional.of(unidad()));
        when(incidenteRepository.save(any(IncidenteAbd.class))).thenReturn(incidente("ALTO"));

        assertNotNull(service.crear(request("ALTO", "foto.jpg", null)));
        verify(alertaRepository).save(any());
    }

    @Test
    void crearNivelBajoNoGeneraAlerta() {
        when(unidadRepository.findById(1)).thenReturn(Optional.of(unidad()));
        when(incidenteRepository.save(any(IncidenteAbd.class))).thenReturn(incidente("BAJO"));

        assertNotNull(service.crear(request("BAJO", null, "Reportado")));
        verify(alertaRepository, never()).save(any());
    }

    @Test
    void crearSinUnidadFalla() {
        when(unidadRepository.findById(1)).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class, () -> service.crear(request("BAJO", null, null)));
    }

    @Test
    void actualizarConEvidenciaYEstado() {
        IncidenteAbd i = incidente("MEDIO");
        when(incidenteRepository.findById(1)).thenReturn(Optional.of(i));
        when(unidadRepository.findById(1)).thenReturn(Optional.of(unidad()));
        when(incidenteRepository.save(any(IncidenteAbd.class))).thenAnswer(a -> a.getArgument(0));

        AbdDtos.IncidenteAbdResponse r = service.actualizar(1, request("MEDIO", "nueva.jpg", "Cerrado"));

        assertEquals("nueva.jpg", r.evidencia());
        assertEquals("Cerrado", r.estado());
    }

    @Test
    void actualizarSinEvidenciaNiEstadoMantiene() {
        IncidenteAbd i = incidente("MEDIO");
        when(incidenteRepository.findById(1)).thenReturn(Optional.of(i));
        when(unidadRepository.findById(1)).thenReturn(Optional.of(unidad()));
        when(incidenteRepository.save(any(IncidenteAbd.class))).thenAnswer(a -> a.getArgument(0));

        AbdDtos.IncidenteAbdResponse r = service.actualizar(1, request("MEDIO", null, null));

        assertEquals("foto.jpg", r.evidencia());
        assertEquals("Reportado", r.estado());
    }

    @Test
    void actualizarInexistenteOSinUnidadFalla() {
        when(incidenteRepository.findById(99)).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class,
                () -> service.actualizar(99, request("BAJO", null, null)));

        when(incidenteRepository.findById(1)).thenReturn(Optional.of(incidente("BAJO")));
        when(unidadRepository.findById(1)).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class,
                () -> service.actualizar(1, request("BAJO", null, null)));
    }

    @Test
    void eliminarOkYNoExiste() {
        when(incidenteRepository.existsById(1)).thenReturn(true);
        service.eliminar(1);
        verify(incidenteRepository).deleteById(1);

        when(incidenteRepository.existsById(99)).thenReturn(false);
        assertThrows(IllegalArgumentException.class, () -> service.eliminar(99));
    }
}
