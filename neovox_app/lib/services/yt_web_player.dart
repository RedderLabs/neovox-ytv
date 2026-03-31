import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

/// YouTube IFrame API player for Flutter web.
class YtWebPlayer {
  static final YtWebPlayer _instance = YtWebPlayer._();
  factory YtWebPlayer() => _instance;
  YtWebPlayer._();

  bool _apiReady = false;
  JSObject? _player;
  Completer<void>? _readyCompleter;

  final _playingController = StreamController<bool>.broadcast();
  final _endedController = StreamController<void>.broadcast();

  Stream<bool> get playingStream => _playingController.stream;
  Stream<void> get endedStream => _endedController.stream;

  bool _playing = false;
  bool get isPlaying => _playing;

  Future<void> init() async {
    if (_apiReady) return;
    _readyCompleter = Completer<void>();

    // Create hidden container in the DOM
    final container = web.document.createElement('div') as web.HTMLDivElement;
    container.id = 'yt-player-wrap';
    container.style.setProperty('position', 'fixed');
    container.style.setProperty('top', '-9999px');
    container.style.setProperty('left', '-9999px');
    container.style.setProperty('width', '1px');
    container.style.setProperty('height', '1px');
    container.style.setProperty('opacity', '0');
    container.style.setProperty('pointer-events', 'none');

    final playerDiv = web.document.createElement('div') as web.HTMLDivElement;
    playerDiv.id = 'yt-audio-player';
    container.appendChild(playerDiv);
    web.document.body!.appendChild(container);

    // Set window.onYouTubeIframeAPIReady callback
    globalContext['onYouTubeIframeAPIReady'] = (() {
      _createPlayer();
    }).toJS;

    // Inject the YouTube IFrame API script
    final script = web.document.createElement('script') as web.HTMLScriptElement;
    script.src = 'https://www.youtube.com/iframe_api';
    web.document.head!.appendChild(script);

    return _readyCompleter!.future;
  }

  void _createPlayer() {
    final onReady = ((JSObject event) {
      _apiReady = true;
      _readyCompleter?.complete();
    }).toJS;

    final onStateChange = ((JSObject event) {
      final data = event['data'];
      if (data == null) return;
      final state = (data as JSNumber).toDartInt;
      // -1=unstarted, 0=ended, 1=playing, 2=paused, 3=buffering, 5=cued
      if (state == 1) {
        _playing = true;
        _playingController.add(true);
      } else if (state == 2 || state == 0 || state == -1) {
        _playing = false;
        _playingController.add(false);
      }
      if (state == 0) {
        _endedController.add(null);
      }
    }).toJS;

    final events = _jsObj({
      'onReady': onReady,
      'onStateChange': onStateChange,
    });

    final playerVars = _jsObj({
      'autoplay': 0.toJS,
      'controls': 0.toJS,
      'disablekb': 1.toJS,
      'fs': 0.toJS,
      'modestbranding': 1.toJS,
      'rel': 0.toJS,
      'playsinline': 1.toJS,
    });

    final options = _jsObj({
      'height': '1'.toJS,
      'width': '1'.toJS,
      'playerVars': playerVars,
      'events': events,
    });

    // new YT.Player('yt-audio-player', options)
    final yt = globalContext['YT'] as JSObject;
    final playerCtor = yt['Player'] as JSFunction;
    _player = playerCtor.callAsConstructorVarArgs<JSObject>(<JSAny?>['yt-audio-player'.toJS, options]);
  }

  void loadAndPlay(String videoId) {
    _call('loadVideoById', [videoId.toJS]);
  }

  void play() {
    _call('playVideo', []);
  }

  void pause() {
    _call('pauseVideo', []);
  }

  void stop() {
    _call('stopVideo', []);
  }

  void seekTo(double seconds) {
    _call('seekTo', [seconds.toJS, true.toJS]);
  }

  void setVolume(int volume) {
    _call('setVolume', [volume.toJS]);
  }

  double getCurrentTime() {
    final r = _call('getCurrentTime', []);
    if (r == null) return 0;
    return (r as JSNumber).toDartDouble;
  }

  double getDuration() {
    final r = _call('getDuration', []);
    if (r == null) return 0;
    return (r as JSNumber).toDartDouble;
  }

  JSAny? _call(String name, List<JSAny> args) {
    if (_player == null) return null;
    final fn = _player![name];
    if (fn == null) return null;
    return (fn as JSFunction).callAsFunction(_player, args.isNotEmpty ? args[0] : null,
        args.length > 1 ? args[1] : null);
  }

  JSObject _jsObj(Map<String, JSAny?> props) {
    final obj = globalContext.callMethod('Object'.toJS) as JSObject? ?? JSObject();
    for (final e in props.entries) {
      obj[e.key] = e.value;
    }
    return obj;
  }
}
