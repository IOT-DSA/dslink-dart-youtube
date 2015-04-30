import "dart:async";

import "package:dslink/client.dart";
import "package:dslink/responder.dart";

import "package:googleapis/youtube/v3.dart";
import 'package:googleapis_auth/auth_io.dart';

LinkProvider link;
AuthClient googleAuthClient;
YoutubeApi youtube;

main(List<String> args) async {
  googleAuthClient = clientViaApiKey("AIzaSyBAWrEREoLjbmBd6gbwSzfV7uEQJvQVTOw");
  youtube = new YoutubeApi(googleAuthClient);

  link = new LinkProvider(args, "YouTube-", command: "run", defaultNodes: {
    "Get Channel Videos": {
      r"$is": "getChannelVideos",
      r"$invokable": "read",
      r"$params": [
        {
          "name": "channel",
          "type": "string"
        },
        {
          "name": "count",
          "type": "integer",
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
    "Get View Count": {
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
    "getChannelVideos": (String path) => new GetChannelVideosNode(path),
    "getViewCount": (String path) => new GetViewCountNode(path)
  });

  if (link.link == null) return;

  link.connect();
}

class GetChannelVideosNode extends SimpleNode {
  GetChannelVideosNode(String path) : super(path);

  @override
  Future<List<Map<String, dynamic>>> onInvoke(Map<String, dynamic> params) async {
    if (params["channel"] == null) [];

    var response = await youtube.search.list("snippet,id", channelId: params["channel"], order: "date");
    return response.items.where((it) => it.id.kind == "youtube#video").map((SearchResult it) => {
      "id": it.id.videoId,
      "title": it.snippet.title,
      "description": it.snippet.description,
      "thumbnail": it.snippet.thumbnails.default_.url,
      "published": it.snippet.publishedAt.toString()
    }).toList();
  }
}

class GetViewCountNode extends SimpleNode {
  GetViewCountNode(String path) : super(path);

  @override
  Future<Map<String, dynamic>> onInvoke(Map<String, dynamic> params) async {
    var id = params["id"];
    if (id == null) return {};
    VideoListResponse videos = await youtube.videos.list("statistics", id: id);
    return {
      "views": videos.items[0].statistics.viewCount
    };
  }
}
