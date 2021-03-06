class MangroveValidation.Models.Island extends Backbone.Model
  paramRoot: 'island'

  url: ->
    if @get('id')?
      "/islands/#{@get('id')}"
    else
      "/islands"

  defaults:
    id: null
    name: null
    name_local: null
    country: null
    iso_3: null
    source: null

  # get gmaps LatLngBounds of this island from cartodb, and pass it to callback
  getBounds: (successCallback, failureCallback) ->
    query = "SELECT ST_Extent(the_geom) AS bbox FROM #{window.CARTODB_TABLE} WHERE id_gid = #{@.get('id')}"
    $.ajax
      url: "#{window.CARTODB_API_ADDRESS}?q=#{query}"
      dataType: 'json'
      success: (data) ->
        # Build the bounds from the WKT bbox
        wktBbox = data.rows[0].bbox
        if wktBbox?
          wktBbox = wktBbox.split('BOX(')[1]
          wktBbox = wktBbox.split(')')[0]

          points = wktBbox.split(',')

          point = points[0].split(' ')
          tl = [point[1], point[0]]

          point = points[1].split(' ')
          br = [point[1], point[0]]

          bounds = [tl, br]
          successCallback(bounds)
        else
          failureCallback() if failureCallback?

class MangroveValidation.Collections.IslandsCollection extends Backbone.Collection
  model: MangroveValidation.Models.Island

  url: ->
    params = {}
    params.query = @query if @query
    params.id = @island_id if @island_id

    if _.isEmpty(params)
      '/islands'
    else
      "/islands?#{$.param(params)}"

  # Get the islands for the given search term
  search: (query, callback) ->
    if(@query == query)
      return false

    @query = query
    @fetch({add: false, success: callback})

  # Gets the island for the given ID
  # Returns the only island
  getAndResetById: (island_id) ->
    if(@island_id == island_id)
      return false

    @island_id = island_id
    @fetch({add: false})
    @get(island_id)
