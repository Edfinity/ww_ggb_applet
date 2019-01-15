# ww_ggb_applet
### Puts Geogebra in WeBWork problems

## Features

- Full, unrestricted use of [Geogebra Api](https://wiki.geogebra.org/en/Reference:GeoGebra_Apps_API)
- Supports multiple Geogebra instances per problem/page
- Helps pass answers invisibly back to answer checkers

## Setup

Add this to your PG problem's setup section:
```
HEADER_TEXT('<script type="text/javascript" src="https://cdn.geogebra.org/apps/deployggb.js"></script>
<script type="text/javascript" src="https://cdn.jsdelivr.net/npm/ww_ggb_applet/lib/ww_ggb_applet.js"></script>');
```

(*Note:* This step is not necessary if your problem will run only in [Edfinity](https://www.edfinity.com), which preloads these libraries.)

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
  new WwGgbApplet('applet1', {width: 400, height: 400, ggbBase64: encodedApp, appletOnLoad: onLoad, appletOnUpdate: onUpdate, hideAnswers: true}); 
</script>
END_SCRIPT

```

Pass the id of the `<div>` tag you create to the constructor. You can pass any Geogebra initialization variables as the second
argument as well as

- `appletOnUpdate`: a function called when Geogebra variables update, and
- `hideAnswers`: hides all student answer blanks

## Applet Methods

Within the load and update callbacks, the ww_ggb_applet object (or bridge object) is available as `this`. The geogebra
applet object is available as `this.applet`.

The bridge object provides these methods:

- `setAnswer(answerId: string, value: string)`
   For a webwork answer id (such as 'AnSwEr0001'), set a value. Usually this value comes from Geogebra via `evalCommand`.
- `getAnswer(answerId: string)`
   Get a student answer, usually to re-insert into Geogebra with `evalCommand`.
- `setCoordinateAnswer(answerId: string, keys: Array, answerKey: string)`
   A convenience method to set an answer from a set of coordinate keys, in the form "key1=(x,y);key2=(x,y);..."
- `setCoordinates(answerId: string, default: object)`
   Take a coordinate value from answerId and insert into the Geogebra applet. The default also provides the object names
   in the form {key1: '(x,y)', key2: '(x,y)'}

## License

This library is released under the [GPL Version 2.0](https://opensource.org/licenses/GPL-2.0) (or later) license.
