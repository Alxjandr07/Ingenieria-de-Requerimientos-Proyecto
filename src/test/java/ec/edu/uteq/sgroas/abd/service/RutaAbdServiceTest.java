package ec.edu.uteq.sgroas.abd.service;

import ec.edu.uteq.sgroas.abd.dto.AbdDtos;
import ec.edu.uteq.sgroas.abd.entity.Ciudad;
import ec.edu.uteq.sgroas.abd.entity.RutaAbd;
import ec.edu.uteq.sgroas.abd.entity.Terminal;
import ec.edu.uteq.sgroas.abd.repository.RutaAbdRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RutaAbdServiceTest {

    @Mock
    private RutaAbdRepository rutaAbdRepository;
    @Mock
    private CatalogoAbdService catalogoAbdService;

    @InjectMocks
    private RutaAbdService service;

    private Terminal terminal(int id, String nombre) {
        return Terminal.builder().idTerminal(id).nombre(nombre)
                .ciudad(Ciudad.builder().idCiudad(1).nombre("Quevedo").build()).build();
    }

    private RutaAbd ruta() {
        return RutaAbd.builder().idRuta(1)
                .terminalOrigen(terminal(1, "T1")).terminalDestino(terminal(2, "T2"))
                .precioPasaje(new BigDecimal("2.50")).build();
    }

    private AbdDtos.RutaAbdRequest request(int origen, int destino) {
        return new AbdDtos.RutaAbdRequest(origen, destino, new BigDecimal("2.50"));
    }

    @Test
    void listarSinSearchUsaFindAllYBlancoTambien() {
        PageRequest pageable = PageRequest.of(0, 10);
        when(rutaAbdRepository.findAll(pageable)).thenReturn(new PageImpl<>(List.of(ruta())));
        when(rutaAbdRepository.contarProgramaciones(1)).thenReturn(0L);

        assertEquals(1, service.listar(null, pageable).getTotalElements());
        assertEquals(1, service.listar("   ", pageable).getTotalElements());
        verify(rutaAbdRepository, times(2)).findAll(pageable);
    }

    @Test
    void listarConSearchUsaBuscar() {
        PageRequest pageable = PageRequest.of(0, 10);
        when(rutaAbdRepository.buscar(eq("quevedo"), eq(pageable)))
                .thenReturn(new PageImpl<>(List.of(ruta())));
        when(rutaAbdRepository.contarProgramaciones(1)).thenReturn(3L);

        assertEquals(3L, service.listar(" Quevedo ", pageable).getContent().get(0).totalProgramaciones());
    }

    @Test
    void buscarPorIdOkYNoEncontrado() {
        when(rutaAbdRepository.findById(1)).thenReturn(Optional.of(ruta()));
        when(rutaAbdRepository.contarProgramaciones(1)).thenReturn(0L);
        assertEquals(1, service.buscarPorId(1).idRuta());

        when(rutaAbdRepository.findById(99)).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class, () -> service.buscarPorId(99));
    }

    @Test
    void crearOkYMismoTerminalFalla() {
        when(catalogoAbdService.buscarTerminal(1)).thenReturn(terminal(1, "T1"));
        when(catalogoAbdService.buscarTerminal(2)).thenReturn(terminal(2, "T2"));
        when(rutaAbdRepository.save(any(RutaAbd.class))).thenReturn(ruta());
        when(rutaAbdRepository.contarProgramaciones(1)).thenReturn(0L);

        assertNotNull(service.crear(request(1, 2)));
        assertThrows(IllegalArgumentException.class, () -> service.crear(request(1, 1)));
    }

    @Test
    void actualizarOkMismoTerminalYNoEncontradaFallan() {
        when(rutaAbdRepository.findById(1)).thenReturn(Optional.of(ruta()));
        when(catalogoAbdService.buscarTerminal(1)).thenReturn(terminal(1, "T1"));
        when(catalogoAbdService.buscarTerminal(2)).thenReturn(terminal(2, "T2"));
        when(rutaAbdRepository.save(any(RutaAbd.class))).thenAnswer(i -> i.getArgument(0));
        when(rutaAbdRepository.contarProgramaciones(1)).thenReturn(0L);

        assertNotNull(service.actualizar(1, request(1, 2)));
        assertThrows(IllegalArgumentException.class, () -> service.actualizar(1, request(2, 2)));

        when(rutaAbdRepository.findById(99)).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class, () -> service.actualizar(99, request(1, 2)));
    }

    @Test
    void eliminarOkYNoExiste() {
        when(rutaAbdRepository.existsById(1)).thenReturn(true);
        service.eliminar(1);
        verify(rutaAbdRepository).deleteById(1);

        when(rutaAbdRepository.existsById(99)).thenReturn(false);
        assertThrows(IllegalArgumentException.class, () -> service.eliminar(99));
    }
}
