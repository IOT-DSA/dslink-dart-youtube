import "dart:async";

import "package:dslink/dslink.dart";
import "package:dslink/nodes.dart";

import "package:googleapis/youtube/v3.dart";
import 'package:googleapis_auth/auth_io.dart';

LinkProvider link;
AuthClient googleAuthClient;
YoutubeApi youtube;

main(List<String> args) async {
  googleAuthClient = clientViaApiKey("AIzaSyBAWrEREoLjbmBd6gbwSzfV7uEQJvQVTOw");
  youtube = new YoutubeApi(googleAuthClient);

  link = new LinkProvider(args, "YouTube-", command: "run", defaultNodes: {
    "Search_Videos": {
      r"$name": "Search Videos",
      r"$is": "searchVideos",
      r"$invokable": "read",
      r"$params": [
        {
          "name": "query",
          "type": "string"
        },
        {
          "name": "channelId",
          "type": "string"
        },
        {
          "name": "max",
          "type": "number",
          "default": 30
        },
        {
          "name": "order",
          "type": buildEnumType([
            "relevance",
            "date",
            "rating",
            "title",
            "videoCount",
            "viewCount"
          ]),
          "default": "relevance"
        },
        {
          "name": "dimension",
          "type": buildEnumType([
            "any",
            "2d",
            "3d"
          ]),
          "default": "any"
        },
        {
          "name": "definition",
          "type": buildEnumType([
            "any",
            "high",
            "standard"
          ]),
          "default": "any"
        }
      ],
      r"$result": "table",
      r"$columns": [
        {
          "name": "id",
          "type": "string"
        },
        {
          "name": "title",
          "type": "string"
        },
        {
          "name": "description",
          "type": "string"
        },
        {
          "name": "thumbnail",
          "type": "string"
        },
        {
          "name": "published",
          "type": "string"
        },
        {
          "name": "url",
          "type": "string"
        },
        {
          "name": "channelId",
          "type": "string"
        },
        {
          "name": "channelTitle",
          "type": "string"
        },
        {
          "name": "liveBroadcastContent",
          "type": buildEnumType([
            "none",
            "live",
            "upcoming"
          ])
        }
      ]
    },
    "Get_Channel_Playlists": {
      r"$name": "Get Channel Playlists",
      r"$is": "getChannelPlaylists",
      r"$invokable": "read",
      r"$params": [
        {
          "name": "channel",
          "type": "string"
        },
        {
          "name": "max",
          "type": "number",
          "default": 20
        }
      ],
      r"$result": "table",
      r"$columns": [
        {
          "name": "id",
          "type": "string"
        },
        {
          "name": "title",
          "type": "string"
        },
        {
          "name": "description",
          "type": "string"
        },
        {
          "name": "thumbnail",
          "type": "string"
        },
        {
          "name": "published",
          "type": "string"
        }
      ]
    },
    "Get_View_Count": {
      r"$name": "Get View Count",
      r"$is": "getViewCount",
      r"$invokable": "read",
      r"$params": [
        {
          "name": "id",
          "type": "string"
        }
      ],
      r"$columns": [
        {
          "name": "views",
          "type": "int"
        }
      ]
    }
  }, profiles: {
    "searchVideos": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) async {
      List<SearchResult> results;
      try {
        results = await getVideos(
            params["max"],
            params["order"],
            channel: params["channelId"],
            query: params["query"],
            definition: params["definition"],
            dimension: params["dimension"]
        );
      } catch (e, stack) {
        return {
          "error": e.toString(),
          "stacktrace": stack.toString()
        };
      }

      return results.map((SearchResult it) => {
        "id": it.id.videoId,
        "title": it.snippet.title,
        "description": it.snippet.description,
        "thumbnail": it.snippet.thumbnails.default_.url,
        "published": it.snippet.publishedAt.toString(),
        "url": "https://www.youtube.com/watch?v=${it.id.videoId}",
        "channelId": it.snippet.channelId,
        "channelTitle": it.snippet.channelTitle,
        "liveBroadcastContent": it.snippet.liveBroadcastContent
      });
    }),
    "getViewCount": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) async {
      var id = params["id"];
      if (id == null) return {};
      try {
        VideoListResponse videos = await youtube.videos.list("statistics", id: id);
        return {
          "views": videos.items[0].statistics.viewCount
        };
      } catch (e) {
        return {};
      }
    }),
    "getChannelPlaylists": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) async {
      if (params["channel"] == null) [];

      List<Playlist> playlists;
      try {
        playlists = await getChannelPlaylists(params["channel"], params["max"]);
      } catch (e) {
        return [];
      }

      return playlists.map((Playlist it) => {
        "id": it.id,
        "title": it.snippet.title,
        "description": it.snippet.description,
        "thumbnail": it.snippet.thumbnails.default_.url,
        "published": it.snippet.publishedAt.toString()
      });
    })
  });

  link.connect();
}

Future<List<Playlist>> getChannelPlaylists(String channel, int max) async {
  if (max == null) max = 0;

  var list = <Playlist>[];
  PlaylistListResponse response;
  String pageToken;
  int currentMax = max;
  while (true) {
    response = await youtube.playlists.list("snippet,id", channelId: channel, maxResults: currentMax == 0 ? null : currentMax, pageToken: pageToken);
    list.addAll(response.items);
    if ((currentMax == 0 || list.length < max) && response.nextPageToken != null) {
      currentMax = max == 0 ? 0 : max - list.length;
      pageToken = response.nextPageToken;
    } else {
      break;
    }
  }
  return list;
}

Future<List<SearchResult>> getVideos(int max, String order, {String channel, String query, String dimension, String definition}) async {
  if (order == null) {
    order = "relevance";
  }

  if (dimension == "any") {
    dimension = null;
  }

  if (definition == "any") {
    definition = null;
  }

  if (query != null && query.isEmpty) {
    query = null;
  }

  if (channel != null && channel.isEmpty) {
    channel = null;
  }

  if (max == null) max = 0;

  var list = <SearchResult>[];
  SearchListResponse response;
  String pageToken;
  int currentMax = max;
  while (true) {
    response = await youtube.search.list(
        "snippet,id",
        channelId: channel,
        q: query,
        order: order,
        maxResults: currentMax == 0 ? null : currentMax,
        pageToken: pageToken,
        type: "youtube#video",
        videoDimension: dimension,
        videoDefinition: definition
    );
    list.addAll(response.items);
    if ((currentMax == 0 || list.length < max) && response.nextPageToken != null) {
      currentMax = max == 0 ? 0 : max - list.length;
      pageToken = response.nextPageToken;
    } else {
      break;
    }
  }
  return list;
}
