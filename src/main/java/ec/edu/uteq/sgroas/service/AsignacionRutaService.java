package ec.edu.uteq.sgroas.service;

import ec.edu.uteq.sgroas.dto.AsignacionRutaRequest;
import ec.edu.uteq.sgroas.dto.AsignacionRutaResponse;
import ec.edu.uteq.sgroas.entity.*;
import ec.edu.uteq.sgroas.repository.AsignacionRutaRepository;
import ec.edu.uteq.sgroas.repository.ConductorRepository;
import ec.edu.uteq.sgroas.repository.RutaRepository;
import ec.edu.uteq.sgroas.repository.VehiculoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AsignacionRutaService {

    private final AsignacionRutaRepository asignacionRutaRepository;
    private final ConductorRepository conductorRepository;
    private final VehiculoRepository vehiculoRepository;
    private final RutaRepository rutaRepository;

    @Transactional(readOnly = true)
    public Page<AsignacionRutaResponse> listar(Pageable pageable) {
        Page<AsignacionRuta> page = asignacionRutaRepository.findByActivoTrue(pageable);
        List<AsignacionRutaResponse> contenido = page.map(this::mapearAResponse).getContent();
        return new PageImpl<>(contenido, pageable, page.getTotalElements());
    }

    @Cacheable(value = "asignaciones", key = "#pageable.pageNumber + '-' + #pageable.pageSize")
    @Transactional(readOnly = true)
    public List<AsignacionRutaResponse> listarCacheable(Pageable pageable) {
        return asignacionRutaRepository.findByActivoTrue(pageable)
                .map(this::mapearAResponse)
                .getContent();
    }

    @Transactional(readOnly = true)
    public AsignacionRutaResponse buscarPorId(Long id) {
        AsignacionRuta asignacion = obtenerAsignacionActiva(id);
        return mapearAResponse(asignacion);
    }

    @CacheEvict(value = "asignaciones", allEntries = true)
    public AsignacionRutaResponse crear(AsignacionRutaRequest request) {
        Conductor conductor = conductorRepository.findById(request.conductorId())
                .filter(Conductor::getActivo)
                .orElseThrow(() -> new IllegalArgumentException("Conductor no encontrado"));

        Vehiculo vehiculo = vehiculoRepository.findById(request.vehiculoId())
                .filter(Vehiculo::getActivo)
                .orElseThrow(() -> new IllegalArgumentException("Vehiculo no encontrado"));

        Ruta ruta = rutaRepository.findById(request.rutaId())
                .filter(Ruta::getActivo)
                .orElseThrow(() -> new IllegalArgumentException("Ruta no encontrada"));

        AsignacionRuta asignacion = AsignacionRuta.builder()
                .conductor(conductor)
                .vehiculo(vehiculo)
                .ruta(ruta)
                .fechaAsignacion(request.fechaAsignacion())
                .fechaInicio(request.fechaInicio())
                .fechaFin(request.fechaFin())
                .estado(convertirEstado(request.estado()))
                .activo(true)
                .creadoEn(Instant.now())
                .actualizadoEn(Instant.now())
                .build();

        AsignacionRuta asignacionGuardada = asignacionRutaRepository.save(asignacion);
        return mapearAResponse(asignacionGuardada);
    }

    @CacheEvict(value = "asignaciones", allEntries = true)
    public AsignacionRutaResponse actualizar(Long id, AsignacionRutaRequest request) {
        AsignacionRuta asignacion = obtenerAsignacionActiva(id);

        Conductor conductor = conductorRepository.findById(request.conductorId())
                .filter(Conductor::getActivo)
                .orElseThrow(() -> new IllegalArgumentException("Conductor no encontrado"));

        Vehiculo vehiculo = vehiculoRepository.findById(request.vehiculoId())
                .filter(Vehiculo::getActivo)
                .orElseThrow(() -> new IllegalArgumentException("Vehiculo no encontrado"));

        Ruta ruta = rutaRepository.findById(request.rutaId())
                .filter(Ruta::getActivo)
                .orElseThrow(() -> new IllegalArgumentException("Ruta no encontrada"));

        asignacion.setConductor(conductor);
        asignacion.setVehiculo(vehiculo);
        asignacion.setRuta(ruta);
        asignacion.setFechaAsignacion(request.fechaAsignacion());
        asignacion.setFechaInicio(request.fechaInicio());
        asignacion.setFechaFin(request.fechaFin());
        asignacion.setEstado(convertirEstado(request.estado()));
        asignacion.setActualizadoEn(Instant.now());

        AsignacionRuta asignacionActualizada = asignacionRutaRepository.save(asignacion);
        return mapearAResponse(asignacionActualizada);
    }

    @CacheEvict(value = "asignaciones", allEntries = true)
    public void desactivar(Long id) {
        AsignacionRuta asignacion = obtenerAsignacionActiva(id);
        asignacion.setActivo(false);
        asignacion.setEstado(EstadoAsignacion.CANCELADA);
        asignacion.setActualizadoEn(Instant.now());
        asignacionRutaRepository.save(asignacion);
    }

    private AsignacionRuta obtenerAsignacionActiva(Long id) {
        return asignacionRutaRepository.findWithDetalle(id)
                .filter(AsignacionRuta::getActivo)
                .orElseThrow(() -> new IllegalArgumentException("Asignacion no encontrada"));
    }

    private EstadoAsignacion convertirEstado(String estado) {
        try {
            return EstadoAsignacion.valueOf(estado.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Estado de asignacion no valido");
        }
    }

    private AsignacionRutaResponse mapearAResponse(AsignacionRuta asignacion) {
        return new AsignacionRutaResponse(
                asignacion.getId(),
                asignacion.getConductor().getId(),
                asignacion.getConductor().getNombres() + " " + asignacion.getConductor().getApellidos(),
                asignacion.getVehiculo().getId(),
                asignacion.getVehiculo().getPlaca(),
                asignacion.getRuta().getId(),
                asignacion.getRuta().getNombre(),
                asignacion.getFechaAsignacion(),
                asignacion.getFechaInicio(),
                asignacion.getFechaFin(),
                asignacion.getEstado().name(),
                asignacion.getActivo(),
                asignacion.getCreadoEn(),
                asignacion.getActualizadoEn()
        );
    }
}
