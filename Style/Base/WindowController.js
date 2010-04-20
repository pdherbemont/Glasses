/**
 * @constructor
 */
var WindowController = function ()
{
}

WindowController.prototype = {
    /**
     * className that the WindowController uses
     * @enum {string}
     */
    Exported: {
        /**
         * className that the WindowController uses
         * @enum {string}
         */
        ClassNames: {
            close: "close",
            miniaturize: "miniaturize",
            zoom: "zoom",
            togglePlaying: "toggle-playing",
            enterFullscreen: "enter-fullscreen",
            leaveFullscreen: "leave-fullscreen",
            timeline: "timeline",
            volume: "volume-slider",
            draggable: "draggable",
            dragPlatformWindow: "drag-platform-window",
            dontDragPlatformWindow: "dont-drag-platform-window",
            resizePlatformWindow: "resize-platform-window",
            autohideWhenMouseLeaves: "autohide-when-mouse-leaves",
            dontHideWhenMouseIsInside: "dont-hide-when-mouse-is-inside",

                /* These are the 'callback' className */
            hidden: "hidden" /* On autohide-when-mouse-leaves elements */
        },
        /**
         * id that the WindowController uses
         * @enum {string}
         */
        Ids: {
            content: "content"
        }
    },
    Imported: {
        /**
         * className that the WindowController expect the backend to use
         * @enum {string}
         */
        ClassNames: {
            playing: "playing"
        }
    },

    init: function()
    {
        // Bind key-equivalent
        document.body.addEventListener('keydown', this.keyDown.bind(this), false);

        // Bind the buttons.
        bindButtonByClassNameToMethod(this.Exported.ClassNames.close, this.close.bind(this));
        bindButtonByClassNameToMethod(this.Exported.ClassNames.miniaturize, this.miniaturize.bind(this));
        bindButtonByClassNameToMethod(this.Exported.ClassNames.zoom, this.zoom.bind(this));
        bindButtonByClassNameToMethod(this.Exported.ClassNames.togglePlaying, this.togglePlaying.bind(this));
        bindButtonByClassNameToMethod(this.Exported.ClassNames.enterFullscreen, this.enterFullscreen.bind(this));
        bindButtonByClassNameToMethod(this.Exported.ClassNames.leaveFullscreen, this.leaveFullscreen.bind(this));

        // Deal with HUD hidding.
        var buttons = document.getElementsByClassName(this.Exported.ClassNames.autohideWhenMouseLeaves);
        if (buttons.length > 0) {
            document.body.addEventListener('mousemove', this.revealAutoHiddenElements.bind(this), false);
            bindByClassNameActionToMethod(this.Exported.ClassNames.dontHideWhenMouseIsInside, 'mouseover', this.interruptAutoHide.bind(this));
        }

        // Make "draggable" elements draggable.
        var draggableElements = document.getElementsByClassName(this.Exported.ClassNames.draggable);
        for (var i = 0; i < draggableElements.length; i++)
            window.dragController.init(draggableElements[i]);

        var elements = document.getElementsByClassName("ellapsed-time");
        for (i = 0; i < elements.length; i++)
            elements[i].bindKey("textContent", "mediaPlayer.time.stringValue");

        elements = document.getElementsByClassName("remaining-time");
        for (i = 0; i < elements.length; i++)
            elements[i].bindKey("textContent", "mediaPlayer.remainingTime.stringValue");

        var mediaList = document.getElementById("mediaList");
        if (mediaList) {
            this.rootMediaList = new MediaListView(CocoaObject.documentCocoaObject(), "rootMediaList.media");
            this.navigationController = new NavigationController;
            this.navigationController.attach(mediaList);

            this.navigationController.push(this.rootMediaList);


            var search = document.getElementById("search-playlist");
            var options = new Object;
            options["NSPredicateFormatBindingOption"] = "metaDictionary.title contains[cd] $value";
            Lunettes.connect(search, "value", this.navigationController, "currentView.arrayController.backendObject.filterPredicate", options);
            Lunettes.connect(CocoaObject.documentCocoaObject(), "backendObject.currentArrayController", this.navigationController, "currentView.arrayController.backendObject");

        }

        // Make sure we'll be able to seek.
        bindByClassNameActionToMethod(this.Exported.ClassNames.timeline, 'change', this.timelineValueChanged.bind(this));
        Lunettes.connect(this, "position", CocoaObject.documentCocoaObject(), "mediaPlayer.position");

        // Make sure we'll be able to change the volume.
        bindByClassNameActionToMethod(this.Exported.ClassNames.volume, 'change', this.volumeValueChanged.bind(this));
        Lunettes.connect(this, "volume", CocoaObject.documentCocoaObject(), "mediaPlayer.audio.volume");

        // Make sure we'll be able to drag the window.
        bindByClassNameActionToMethod(this.Exported.ClassNames.dragPlatformWindow, 'mousedown', this.mouseDownForWindowDrag.bind(this));

        // Make sure we'll be able to resize the window.
        bindByClassNameActionToMethod(this.Exported.ClassNames.resizePlatformWindow, 'mousedown', this.mouseDownForWindowResize.bind(this));
    },

    /**
     * @param {Event} event
     */
    volumeValueChanged: function(event)
    {
        var target = event.currentTarget;

        this.volume = target.value;
        event.preventDefault();
    },

    _volume: 0,
    get volume()
    {
        return this._volume;
    },
    set volume(volume)
    {
        if (!volume)
            volume = 0;
        if (this._volume == volume)
            return;

        Lunettes.willChange(this, "volume");
        this._volume = parseInt(volume, 10);

        var elements = document.getElementsByClassName(this.Exported.ClassNames.volume);
        for (var i = 0; i < elements.length; i++) {
            if (elements[i].value != volume)
                elements[i].value = volume;
        }
        Lunettes.didChange(this, "volume");
    },

    /**
     * @param {Event} event
     */
    timelineValueChanged: function(event)
    {
        var target = event.currentTarget;

        if (window.PlatformView.isSeekable())
            window.PlatformView.setPosition_(target.value / target.getAttribute('max'));
    },

    _position: 0,
    get position()
    {
        return this._position;
    },
    set position(newPosition)
    {
        if (!newPosition)
            newPosition = 0;
        if (this._position == newPosition)
            return;

        this._position = newPosition;

        var elements = document.getElementsByClassName(this.Exported.ClassNames.timeline);
        for (var i = 0; i < elements.length; i++)
            elements[i].value = newPosition * elements[i].getAttribute('max');
    },
    PlatformWindowController: function()
    {
        return window.PlatformWindowController;
    },

    PlatformWindow: function()
    {
        return window.PlatformWindow;
    },

    /**
     * @param {string} className
     */
    contentHasClassName: function(className)
    {
        var content = document.getElementById(this.Exported.Ids.content);
        return content.hasClassName(className) != -1;
    },

    /**
     * @param {string} className
     */
    removeClassNameFromContent: function(className)
    {
        var content = document.getElementById(this.Exported.Ids.content);
        content.removeClassName(className);
    },

    /**
     * @param {string} className
     */
    addClassNameToContent: function(className)
    {
        var content = document.getElementById(this.Exported.Ids.content);
        content.addClassName(className);
    },

    // JS -> Core

    close: function()
    {
        this.PlatformWindow().performClose();
    },

    miniaturize: function()
    {
        this.PlatformWindow().miniaturize();
    },

    zoom: function()
    {
        this.PlatformWindow().zoom();
    },

    /**
     * @param {Event} event
     */
    togglePlaying: function(event)
    {
        if(this.contentHasClassName(this.Imported.ClassNames.playing))
            window.PlatformView.pause();
        else
            window.PlatformView.play();
        event.preventDefault();
    },

    /**
     * @param {Event} event
     */
    enterFullscreen: function(event)
    {
        this.PlatformWindowController().enterFullscreen();
        event.preventDefault();
    },

    /**
     * @param {Event} event
     */
    leaveFullscreen: function(event)
    {
        this.PlatformWindowController().leaveFullscreen();
        event.preventDefault();
    },

    videoResized: function()
    {
        if (window.PlatformView.videoDidResize)
            window.PlatformView.videoDidResize();
    },

    windowResized: function()
    {
        this.videoResized();
    },


    windowFrame: function()
    {
        var platformWindow = this.PlatformWindow();
        var origin = { x: platformWindow.frameOriginX(), y: platformWindow.frameOriginY() };
        var size = { height: platformWindow.frameSizeHeight(), width: platformWindow.frameSizeWidth() };
        return { origin: origin, size: size };
    },

    /*************************************************
     * Event handlers
     */

    /**
     * Key events
     * @param {Event} event
     */
    keyDown: function(event)
    {
        var key = event.keyCode;

        // Space" key
        if (key == 0x20)
            this.togglePlaying();
    },

    // Common

    mouseDownPoint: null,
    windowFrameAtMouseDown: null,

    /**
     * @param {Event} event
     */
    saveMouseDownInfo: function(event)
    {
        this.mouseDownPoint = { x: event.screenX, y: event.screenY };
        this.windowFrameAtMouseDown = this.windowFrame();
    },

    /*************************************************
     * Window Drag
     */

    /**
     * @param {Event} event
     */
    mouseDownForWindowDrag: function(event)
    {
        // It is reasonnable to only allow click in div, to mouve the window
        // This could probaby be refined
        if (event.srcElement.nodeName != "DIV"
            || event.srcElement.hasClassName(this.Exported.ClassNames.resizePlatformWindow)
            || event.srcElement.hasClassNameInAncestors(this.Exported.ClassNames.dontDragPlatformWindow)) {
            return;
        }
        this.saveMouseDownInfo(event);

        // Sometimes we may get multiple mouseDown but no mouseUp
        // make sure we don't register the listener twice.
        if (this._mouseUpListener)
            return;

        this._mouseUpListener = this.mouseUpForWindowDrag.bind(this);
        this._mouseDragListener = this.mouseDraggedForWindowDrag.bind(this);
        document.addEventListener('mouseup', this._mouseUpListener, false);
        document.addEventListener('mousemove', this._mouseDragListener, false);
    },

    /**
     * @param {Event} event
     */
    mouseUpForWindowDrag: function(event)
    {
        document.removeEventListener('mouseup', this._mouseUpListener, false);
        document.removeEventListener('mousemove', this._mouseDragListener, false);
        this._mouseUpListener = null;
        this._mouseDragListener = null;
    },

    /**
     * @param {Event} event
     */
    mouseDraggedForWindowDrag: function(event)
    {
        var dx = this.mouseDownPoint.x - event.screenX;
        var dy = this.mouseDownPoint.y - event.screenY;
        var mouseDownOrigin = this.windowFrameAtMouseDown.origin;
        this.PlatformWindow().setFrameOrigin__(mouseDownOrigin.x - dx, mouseDownOrigin.y + dy);
    },

    /*************************************************
     * Window Resize
     */

    /**
     * @param {Event} event
     */
    mouseDownForWindowResize: function(event)
    {
        // It is reasonnable to only allow click in element that have a resize class
        if (!event.srcElement.hasClassName(this.Exported.ClassNames.resizePlatformWindow))
            return;

        this.saveMouseDownInfo(event);

        this.PlatformWindow().willStartLiveResize();

        this._mouseUpForWindowResizeListener = this.mouseUpForWindowResize.bind(this);
        this._mouseDragForWindowResizeListener = this.mouseDraggedForWindowResize.bind(this);
        document.addEventListener('mouseup', this._mouseUpForWindowResizeListener, false);
        document.addEventListener('mousemove', this._mouseDragForWindowResizeListener, false);
    },

    /**
     * @param {Event} event
     */
    mouseUpForWindowResize: function(event)
    {
        document.removeEventListener('mouseup', this._mouseUpForWindowResizeListener, false);
        document.removeEventListener('mousemove', this._mouseDragForWindowResizeListener, false);

        this.PlatformWindow().didEndLiveResize();
    },

    /**
     * @param {Event} event
     */
    mouseDraggedForWindowResize: function(event)
    {
        var dx = event.screenX - this.mouseDownPoint.x;
        var dy = event.screenY - this.mouseDownPoint.y;
        var mouseDownOrigin = this.windowFrameAtMouseDown.origin;
        var mouseDownSize = this.windowFrameAtMouseDown.size;

        var platformWindow = this.PlatformWindow();
        platformWindow.setFrame(mouseDownOrigin.x, mouseDownOrigin.y - dy, mouseDownSize.width + dx, mouseDownSize.height + dy);
        this.windowResized();
    },

    /*************************************************
     * HUD autohide
     */
    timer: null,
    autohiddingTime: 0.5,

    /**
     * @param {Event} event
     */
    autoHideElements: function(event)
    {
        window.PlatformView.hideCursorUntilMouseMoves();
        this.addClassNameToContent(this.Exported.ClassNames.hidden);
    },

    // We have a dummy mouseMove events that triggers "revealAutoHiddenElementsAndHideAfter"
    // that gets sent anyway. This makes the HUD show up when the HUD is put on screen.
    // This is not what we want so skip it.
    globalIsFirstMouseMove: true,

    revealAutoHiddenElementsAndHideAfter: function(seconds, element)
    {
        if (this.globalIsFirstMouseMove) {
            this.globalIsFirstMouseMove = false;
            return;
        }

        this.removeClassNameFromContent(this.Exported.ClassNames.hidden);
        var timer = this.timer;
        if (timer)
            window.clearTimeout(timer);
        if (element && element.hasClassNameInAncestors(this.Exported.ClassNames.dontHideWhenMouseIsInside))
            return;
        this.timer = window.setTimeout(this.autoHideElements.bind(this), seconds * 1000);
    },

    /**
     * @param {Event} event
     */
    revealAutoHiddenElements: function(event)
    {
        this.revealAutoHiddenElementsAndHideAfter(this.autohiddingTime, event.srcElement);
    },

    /**
     * @param {Event} event
     */
    interruptAutoHide: function(event)
    {
        var timer = this.timer;
        if (!timer)
            return;
        window.clearTimeout(timer);
        timer = null;
    }
}

window.windowController = new WindowController;

