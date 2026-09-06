package ec.edu.uteq.sgroas.repository;

import ec.edu.uteq.sgroas.entity.AsignacionRuta;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface AsignacionRutaRepository extends JpaRepository<AsignacionRuta, Long> {

    @EntityGraph(attributePaths = {"conductor", "vehiculo", "ruta"})
    Page<AsignacionRuta> findByActivoTrue(Pageable pageable);

    @Query("SELECT a FROM AsignacionRuta a JOIN FETCH a.conductor JOIN FETCH a.vehiculo JOIN FETCH a.ruta WHERE a.id = :id")
    Optional<AsignacionRuta> findWithDetalle(@Param("id") Long id);

    List<AsignacionRuta> findByConductorIdAndActivoTrue(Long conductorId);

    List<AsignacionRuta> findByVehiculoIdAndActivoTrue(Long vehiculoId);

    List<AsignacionRuta> findByRutaIdAndActivoTrue(Long rutaId);

    @Procedure(name = "AsignacionRuta.asignacionesActivasPorConductor")
    List<Object[]> asignacionesActivasPorConductor(@Param("p_conductor_id") Long conductorId);
}
