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

Continuing in the setup section, start with this example code:

```
TEXT( MODES(TeX=>'', HTML=><<END_SCRIPT ) );
<div id="applet1" class="ww-ggb"></div>

<script>
  var wwGgb = null;
  
  var onUpdate = function(obj) {
    // called when any applet variable changes
  }

  var onLoad = function(applet) {
    // called once on load
    applet.evalCommand("L = Line[A, B]");
  }
  
  encodedApp = "Your encoded app here";
  wwGgb = new WwGgbApplet('applet1', {width: 400, height: 400, ggbBase64: encodedApp, appletOnLoad: onLoad, appletOnUpdate: onUpdate, hideAnswers: true}); 
</script>
END_SCRIPT

```

Pass the id of the `<div>` tag you create to the constructor. You can pass any Geogebra initialization variables as the second
argument as well as

- `appletOnUpdate`: a function called when Geogebra variables update, and
- `hideAnswers`: hides all student answer blanks


