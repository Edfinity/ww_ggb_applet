# ww_ggb_applet
### Puts Geogebra in WeBWorK problems

## Features

- Allows unrestricted use of [Geogebra API](https://wiki.geogebra.org/en/Reference:GeoGebra_Apps_API)
- Supports multiple Geogebra instances per problem/page
- Helps pass answers invisibly back to answer checkers
- (Optionally) Saves state like the WeBWorK Geogebra implementation

## Setup

Add this to your PG problem's setup section. *Note:* This step is not necessary if your problem will run only in [Edfinity](https://www.edfinity.com), which preloads these libraries.

```
HEADER_TEXT('<script type="text/javascript" src="https://cdn.geogebra.org/apps/deployggb.js"></script>
<script type="text/javascript" src="https://cdn.jsdelivr.net/npm/ww_ggb_applet/lib/ww_ggb_applet.js"></script>');
```

Continuing in the setup section, start with this example code:

```
TEXT( MODES(TeX=>'', HTML=><<END_SCRIPT ) );
<div id="applet1" class="ww-ggb"></div>

<script>
  var onUpdate = function(obj) {
    // called when any applet variable changes
  }

  var onLoad = function(applet) {
    // called once on load
    applet.evalCommand("L = Line[A, B]");
  }

  encodedApp = "Your encoded app here";
  var applet = new WwGgbApplet('applet1', {ggbBase64: encodedApp, appletOnLoad: onLoad, appletOnUpdate: onUpdate, hideAnswers: true});

  # do _not_ include the next line when running within Edfinity
  applet.build();
</script>
END_SCRIPT

```

Pass the id of the `<div>` tag you create to the constructor along with constructor parameters. You can pass any Geogebra initialization variables as parameters.

## Parameters (constructor)

- `appletOnLoad`: Optional. Function called every time the applet is loaded
- `appletOnUpdate`: Optional. Function called when Geogebra variables update
- `ggbBase64`: Required. Base64-encoded Geogebra applet.
- `height`: Optional. Applet height.
- `hideAnswers`: [false] Hides all student answer inputs; if you only need to hide certain input fields, use `hideAnswer` instead.
- `resetButton`: [false] Whether to display a button that lets the user reset the applet state. `saveState` must be true when setting `resetButton` to true.
- `resetButtonLabel`: [Reset] Reset button label.
- `saveState`: [false]. If true, trigger an `applet-update` event when the applet is updated. Within Edfinity, this will automatically save the state of the applet. Outside of Edfinity, you will need to listen for this event and persist the state manually.
- `width`: Optional. Applet width.

Within the `appletOnLoad` and `appletOnUpdate` callbacks, the `WwGgbApplet` object (or bridge object) is available as `this`. The geogebra applet object is available as `this.applet`.

## Methods

- `getAnswer(answerId: string)`:
  Get a student answer, usually to re-insert into Geogebra with `evalCommand`.
- `hideAnswer(answerId: string)`:
  Hides the given WeBWorK answer.
- `setAnswer(answerId: string, value: string)`:
  For a WeBWorK answer id (such as 'AnSwEr0001'), set a value. Usually this value comes from Geogebra via `evalCommand`.
- `setCoordinateAnswer(answerId: string, keys: Array, answerKey: string)`:
   A convenience method to set an answer from a set of coordinate keys, in the form "key1=(x,y);key2=(x,y);..."
- `setCoordinates(answerId: string, default: object)`:
   Take a coordinate value from answerId and insert into the Geogebra applet. The default also provides the object names
   in the form {key1: '(x,y)', key2: '(x,y)'}

## Events

The bridge object triggers JQuery events on the applet's element. The event parameters are `ggb` (bridge object) and `applet` (applet).

- `applet-reset`: Fired when applet is reset.
- `applet-update`: Fired when applet is updated.
- `applet-load`: Fired when applet is loaded.
- `applet-focusout`: Fired when focus leaves applet.


## License

This library is released under the [GPL Version 2.0](https://opensource.org/licenses/GPL-2.0) (or later) license.
