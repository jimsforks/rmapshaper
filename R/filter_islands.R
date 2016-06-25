#' Remove small detached polygons (islands)
#'
#' Remove small detached polygons, keeping those with a minimum area and/or a
#' minimum number of vertices. Optionally remove null geomtries.
#'
#' @param input spatial object to filter - can be a
#'   \code{SpatialPolygonsDataFrame} or class \code{geo_json} or \code{geo_list}
#' @param min_area minimum area of polygons to retain. Area is calculated using
#'  planar geometry, except for the area of unprojected polygons, which is
#'  calculated using spherical geometry in units of square meters.
#' @param min_vertices minimum number of vertices in polygons to retain.
#' @param drop_null_geometries should features with empty geometries be dropped?
#'   Default \code{TRUE}. Ignored for \code{Spatial*DataFrames}, as it is always
#'   \code{TRUE}.
#' @param force_FC should the output be forced to be a \code{FeatureCollection}
#'   even if there are no attributes? Default \code{TRUE}.
#'   \code{FeatureCollections} are more compatible with \code{rgdal::readOGR}
#'   and \code{geojsonio::geojson_sp}. If \code{FALSE} and there are no
#'   attributes associated with the geometries, a \code{GeometryCollection} will
#'   be output. Ignored for \code{Spatial} objects, as a
#'   \code{Spatial*DataFrame} is always the output.
#'
#' @return object with only specified features retained, in the same class as
#'   the input
#' @export
ms_filter_islands <- function(input, min_area = NULL, min_vertices = NULL, drop_null_geometries = TRUE, force_FC = TRUE) {
  if (!is.null(min_area) && !is.numeric(min_area)) stop("min_area must be numeric")
  if (!is.null(min_vertices) && !is.numeric(min_vertices)) stop("min_vertices must be numeric")
  if (!is.logical(drop_null_geometries)) stop("drop_null_geometries must be TRUE or FALSE")
  if (!is.logical(force_FC)) stop("force_FC must be TRUE or FALSE")
  UseMethod("ms_filter_islands")
}

#' @describeIn ms_filter_islands For character representations of geojson (for example
#' if you used \code{readLines} to read in a geojson file)
#' @export
ms_filter_islands.character <- function(input, min_area = NULL, min_vertices = NULL, drop_null_geometries = TRUE, force_FC = TRUE) {
  input <- check_character_input(input)

  cmd <- make_filterislands_call(min_area = min_area, min_vertices = min_vertices,
                                 drop_null_geometries = drop_null_geometries)

  apply_mapshaper_commands(data = input, command = cmd, force_FC = force_FC)

}

#' @describeIn ms_filter_islands Method for geo_json
#' @export
ms_filter_islands.geo_json <- function(input, min_area = NULL, min_vertices = NULL, drop_null_geometries = TRUE, force_FC = TRUE) {
  cmd <- make_filterislands_call(min_area = min_area, min_vertices = min_vertices,
                                 drop_null_geometries = drop_null_geometries)

  apply_mapshaper_commands(data = input, command = cmd, force_FC = force_FC)
}

#' @describeIn ms_filter_islands Method for geo_list
#' @export
ms_filter_islands.geo_list <- function(input, min_area = NULL, min_vertices = NULL, drop_null_geometries = TRUE, force_FC = TRUE) {
  geojson <- geojsonio::geojson_json(input)

  cmd <- make_filterislands_call(min_area = min_area, min_vertices = min_vertices,
                                 drop_null_geometries = drop_null_geometries)

  ret <- apply_mapshaper_commands(data = geojson, command = cmd, force_FC = force_FC)

  geojsonio::geojson_list(ret)
}

#' @describeIn ms_filter_islands Method for SpatialPolygonsDataFrame
#' @export
ms_filter_islands.SpatialPolygonsDataFrame <- function(input, min_area = NULL, min_vertices = NULL, drop_null_geometries = TRUE, force_FC = TRUE) {
  ms_filter_islands_sp(input, min_area = min_area, min_vertices = min_vertices)
}


ms_filter_islands_sp <- function(input, min_area = NULL, min_vertices = NULL) {

  cmd <- make_filterislands_call(min_area = min_area, min_vertices = min_vertices,
                                 drop_null_geometries = TRUE)

  geojson <- sp_to_GeoJSON(input)

  ret <- apply_mapshaper_commands(data = geojson, command = cmd, force_FC = TRUE)

  GeoJSON_to_sp(ret, proj = attr(geojson, "proj4"))
}

make_filterislands_call <- function(min_area, min_vertices, drop_null_geometries) {

  if (!is.null(min_area)) min_area <- paste0("min-area=", min_area)
  if (!is.null(min_vertices)) min_vertices <- paste0("min-vertices=", min_vertices)

  if (drop_null_geometries) rem <- "remove-empty" else rem <- NULL

  call <- list("-filter-islands", min_area, min_vertices, rem)
  call
}