
-----------------------------------------------------------------
-- MATERIALIZED VIEW QGIS_BSTSAI."=LMV_CITYDB_SOL_VEG_OBJ_LOD3_IMPLICIT_ATTRI_TABLE"
-----------------------------------------------------------------
DROP MATERIALIZED VIEW IF EXISTS qgis_bstsai."=lmv_citydb_sol_veg_obj_lod3_Implicit_attri_table" CASCADE;
CREATE MATERIALIZED VIEW         qgis_bstsai."=lmv_citydb_sol_veg_obj_lod3_Implicit_attri_table" AS

SELECT
	g.f_id AS f_id,
	g.f_object_id AS f_object_id,
	g.geom AS geom,
	a."crownDiameter",
	a."crownDiameter_UoM",
	a."height",
	a."height_UoM",
	a."name",
	a."species"
FROM qgis_bstsai."_g_citydb_sol_veg_obj_lod3_Implicit" AS g
		LEFT JOIN qgis_bstsai."_amv_citydb_SolitaryVegetationObject_g_17_attributes" AS a ON g.f_id = a.f_id;
		
CREATE INDEX "citydb_sol_veg_obj_lod3_Implicit_attri_table_g_1_f_id_idx" ON qgis_bstsai."=lmv_citydb_sol_veg_obj_lod3_Implicit_attri_table" (f_id);
CREATE INDEX "citydb_sol_veg_obj_lod3_Implicit_attri_table_g_2_o_id_idx" ON qgis_bstsai."=lmv_citydb_sol_veg_obj_lod3_Implicit_attri_table" (f_object_id);
CREATE INDEX "citydb_sol_veg_obj_lod3_Implicit_attri_table_g_3_geom_spx" ON qgis_bstsai."=lmv_citydb_sol_veg_obj_lod3_Implicit_attri_table" USING gist (geom);
CREATE INDEX "citydb_sol_veg_obj_lod3_Implicit_attri_table_a_1" ON qgis_bstsai."=lmv_citydb_sol_veg_obj_lod3_Implicit_attri_table" ("crownDiameter");
CREATE INDEX "citydb_sol_veg_obj_lod3_Implicit_attri_table_a_2" ON qgis_bstsai."=lmv_citydb_sol_veg_obj_lod3_Implicit_attri_table" ("crownDiameter_UoM");
CREATE INDEX "citydb_sol_veg_obj_lod3_Implicit_attri_table_a_3" ON qgis_bstsai."=lmv_citydb_sol_veg_obj_lod3_Implicit_attri_table" ("height");
CREATE INDEX "citydb_sol_veg_obj_lod3_Implicit_attri_table_a_4" ON qgis_bstsai."=lmv_citydb_sol_veg_obj_lod3_Implicit_attri_table" ("height_UoM");
CREATE INDEX "citydb_sol_veg_obj_lod3_Implicit_attri_table_a_5" ON qgis_bstsai."=lmv_citydb_sol_veg_obj_lod3_Implicit_attri_table" ("name");
CREATE INDEX "citydb_sol_veg_obj_lod3_Implicit_attri_table_a_6" ON qgis_bstsai."=lmv_citydb_sol_veg_obj_lod3_Implicit_attri_table" ("species");
ALTER TABLE qgis_bstsai."=lmv_citydb_sol_veg_obj_lod3_Implicit_attri_table" OWNER TO bstsai;
REFRESH MATERIALIZED VIEW qgis_bstsai."=lmv_citydb_sol_veg_obj_lod3_Implicit_attri_table"; 
DELETE FROM qgis_bstsai.layer_metadata AS l WHERE l.cdb_schema = 'citydb' AND l.layer_name = '"=lmv_citydb_sol_veg_obj_lod3_Implicit_attri_table"';
INSERT INTO qgis_bstsai.layer_metadata (
	cdb_schema, feature_type, parent_objectclass_id, parent_classname, objectclass_id, 
	classname, lod, layer_name, gv_name, inline_attris, nested_attris, is_all_attris, 
	av_table_name, n_features, creation_date)
VALUES (
	'citydb','Vegetation',0,'null',1301,
	'SolitaryVegetationObject','lod3','"=lmv_citydb_sol_veg_obj_lod3_Implicit_attri_table"','"_g_citydb_sol_veg_obj_lod3_Implicit"','{crownDiameter,height,name,species}',,'true', 
	'"_amv_citydb_SolitaryVegetationObject_g_17_attributes"',33, clock_timestamp());