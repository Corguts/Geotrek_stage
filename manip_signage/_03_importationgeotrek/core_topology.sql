--insertion des points en ajoutant le geom 3d
/*j'avais un probleme les 3 premiers sont les null donc a chaque fois ça ne marchait pas
 evidemment donc j'ai juste changé l'odre selon id pour avoir quelque chose qui marche
  et ca a bien marché,reste a créer les signalétiques selon l'id de topology*/
INSERT INTO public.core_topology (geom, geom_3d, kind)
SELECT geom_topo,
       ST_Force3D(geom_topo) AS geom_3d,
       'SIGNAGE' AS kind
FROM geotrek.signage_intersection;


--import de l'altitude dans min_elevation et max_elevation dans topology
UPDATE public.core_topology
SET min_elevation = (
        SELECT MIN(ST_Value(altimetry_dem.rast, core_topology.geom))
        FROM public.altimetry_dem
        WHERE ST_Intersects(altimetry_dem.rast, core_topology.geom)
        AND core_topology.id > 48
    ),
    max_elevation = (
        SELECT MAX(ST_Value(altimetry_dem.rast, core_topology.geom))
        FROM public.altimetry_dem
        WHERE ST_Intersects(altimetry_dem.rast, core_topology.geom)
        AND core_topology.id > 48
    )
WHERE core_topology.id > 48;


/*l'élévation est donné sur topology, la question qui se pose , 
est il posé de mettre en place des triggers pour automatiser 
lorsque max_elevation de topology est complété,
qu' il mette automatiquement sur printed_elevation de signage*/
--idée de trigger proposé
/*CREATE TRIGGER update_printed_elevation
AFTER INSERT ON core_topology
FOR EACH ROW
BEGIN
    UPDATE signage_signage
    SET printed_elevation = NEW.max_elevation
    WHERE core_topology_id = NEW.id;
END;
*/