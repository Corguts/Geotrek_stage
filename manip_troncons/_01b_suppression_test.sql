
--suppression des tracés tests pour trek(itinéraire)
DELETE FROM trekking_orderedtrekchild;
DELETE FROM trekking_trekrelationship;
DELETE FROM trekking_trek_networks
WHERE trek_id <> 17653;
DELETE FROM trekking_trek
WHERE departure_fr IS NULL OR departure = '';
DELETE FROM trekking_trek_ratings;
DELETE FROM trekking_trek
WHERE name = 'GR®65 Figeac - Béduer';
DELETE FROM core_pathaggregation
WHERE topo_object_id IN (
    SELECT id
    FROM core_topology
    WHERE kind = 'TREK' AND deleted = TRUE
);
DELETE FROM core_certificationtrail;
DELETE FROM core_trail;
DELETE  FROM core_topology
WHERE deleted = TRUE AND kind = 'TREK';

--suppression des tracés tests pour trail(sentiers)
DELETE FROM core_pathaggregation
WHERE topo_object_id IN (
    SELECT id
    FROM core_topology
    WHERE kind = 'TRAIL' AND deleted = TRUE
);
DELETE  FROM core_topology
WHERE deleted = TRUE AND kind = 'TRAIL';


DELETE FROM core_topology
WHERE kind = 'LANDEDGE';
