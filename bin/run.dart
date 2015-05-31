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
    "Get_Channel_Videos": {
      r"$name": "Get Channel Videos",
      r"$is": "getChannelVideos",
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
    "getChannelVideos": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) async {
      if (params["channel"] == null) [];

      List<SearchResult> results;
      try {
        results = await getChannelVideos(params["channel"], params["max"]);
      } catch (e) {
        return [];
      }

      return results.map((SearchResult it) => {
        "id": it.id.videoId,
        "title": it.snippet.title,
        "description": it.snippet.description,
        "thumbnail": it.snippet.thumbnails.default_.url,
        "published": it.snippet.publishedAt.toString()
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

Future<List<SearchResult>> getChannelVideos(String channel, int max) async {
  if (max == null) max = 0;

  var list = <SearchResult>[];
  SearchListResponse response;
  String pageToken;
  int currentMax = max;
  while (true) {
    response = await youtube.search.list("snippet,id", channelId: channel, maxResults: currentMax == 0 ? null : currentMax, pageToken: pageToken, type: "youtube#video");
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
