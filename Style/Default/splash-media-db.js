/**
 * A list of SDView
 * @constructor
 * @extends ListView
 * @param {CocoaObject} cocoaObject
 * @param {string} subItemsKeyPath
 * @param {Element} elementTag
 */
var SDListView = function(cocoaObject, subItemsKeyPath, elementTag)
{
    ListView.call(this, cocoaObject, subItemsKeyPath, SDView, elementTag);

    this.element.addClassName("sd-list-view");

    this.displayName = "SDListView";
    this._selectionHeight = 200;
    this._shouldSyncSelectionWithArrayController = false;
    this._shouldAutoSelectInsertedItem = false;
}

SDListView.prototype = {
    unselectAllBeforeSelection: function()
    {
        ListView.prototype.unselectAllBeforeSelection.call(this);
        window.unselectAll();
    },
    unselectAll: function()
    {
        // Prevent unselectingAll
    },
    select: function(item)
    {
        ListView.prototype.select.call(this, item);
        if (!item)
            return;
        if (!item._list) {
            item._list = new ListView(item.cocoaObject, "discoveredMedia.media", MediaSDView);
            item._list.searchMainKeyPath = "metaDictionary.title";
        }
        window.setDetailList(item.element, item._list);
    },

    updateVisibleItems: function()
    {
        ListView.prototype.updateVisibleItems.call(this);

        var sourcesHeaderShouldBeMadeVisible = this.subviews.length > 0;
        var needToUpdateVisibility = sourcesHeaderShouldBeMadeVisible ^ window._isSourcesHeaderVisible;
        if (needToUpdateVisibility) {
            var sourcesHeaderElement = document.getElementById("sources-header");
            if (sourcesHeaderShouldBeMadeVisible)
                sourcesHeaderElement.removeClassName("hidden");
            else
                sourcesHeaderElement.addClassName("hidden");
            window._isSourcesHeaderVisible = sourcesHeaderShouldBeMadeVisible;
        }

    }
}
SDListView.prototype.__proto__ = ListView.prototype;


/**
 * A list of SDView
 * @constructor
 * @extends ListItemView
 * @param {CocoaObject} cocoaObject
 * @param {Object} parent
 * @param {string} elementTag
 */
var SDView = function(cocoaObject, parent, elementTag)
{
    ListItemView.call(this, cocoaObject, parent, elementTag);
    this.element.addClassName("sd-view");
}

SDView.prototype = {
    createSubElements: function()
    {
        this.nameElement = document.createElement("div");
        this.nameElement.className = "name";

        this.subitemsCountElement = document.createElement("div");
        this.subitemsCountElement.className = "subitems-count";

        this.imgElement = document.createElement("img");
        this.imgElement.src = "sources.png"
    },

    appendSubElementsToNode: function(element)
    {
        element.appendChild(this.imgElement);
        element.appendChild(this.nameElement);
        element.appendChild(this.subitemsCountElement);
    },

    set visible(visible)
    {
        if (this._visible == visible)
            return;

        ListItemView.prototype.__lookupSetter__("visible").call(this, visible);

        if (visible) {
            Lunettes.connect(this.nameElement, "textContent", this.cocoaObject, "localizedName");
            Lunettes.connect(this.subitemsCountElement, "textContent", this.cocoaObject, "discoveredMedia.media.@count");
        } else {
            Lunettes.unconnect(this.nameElement, "textContent");
            Lunettes.unconnect(this.subitemsCountElement, "textContent");
        }
    },

    /**
     * When double clicked
     */
    action: function()
    {
    }

}
SDView.prototype.__proto__ = ListItemView.prototype;

/**
 * A list of MediaSDView
 * @constructor
 * @extends MediaView
 * @param {CocoaObject} cocoaObject
 * @param {Object} parent
 * @param {string} elementTag
 */
var MediaSDView = function(cocoaObject, parent, elementTag)
{
    MediaView.call(this, cocoaObject, parent, elementTag);
    this.element.addClassName("media-sd-view");
}


MediaSDView.prototype = {
    action: function(parentElement)
    {
        window.PlatformView.playMediaDiscovererWithMedia(this.parent.cocoaObject, this.cocoaObject);
    }
}
MediaSDView.prototype.__proto__ = MediaView.prototype;

/**
 * A list of MediaDBView
 * @constructor
 * @extends MediaView
 * @param {CocoaObject} cocoaObject
 * @param {Object} parent
 * @param {string} elementTag
 */

var MediaDBView = function(cocoaObject, parent, elementTag)
{
    MediaView.call(this, cocoaObject, parent, elementTag);
    this.element.addClassName("media-db-view");
}

MediaDBView.prototype = {
    createSubElements: function()
    {
        this.detailElement = document.createElement("div");
        this.detailElement.className = "detail";

        this.nameElement = document.createElement("div");
        this.nameElement.className = "name";

        this.shortSummaryElement = document.createElement("div");
        this.shortSummaryElement.className = "short-summary";

        this.detailElement.appendChild(this.nameElement);
        this.detailElement.appendChild(this.shortSummaryElement);

        this.yearElement = document.createElement("div");
        this.yearElement.className = "year";

        this.thumbnailElement = document.createElement("img");
        this.thumbnailElement.className = "thumbnail";

        this.statusElement = document.createElement("div");
        this.statusElement.className = "status";


        if (!MediaDBView.actionPopUp) {
            var button = document.createElement("select");
            button.className = "action-button";
            function addOption(button, text, value) {
                var opt = document.createElement("option");
                opt.text = text;
                opt.value = value;
                button[value] = opt;
                button.appendChild(opt);
                return opt;
            }
            addOption(button, "Remove...", "remove");
            addOption(button, "Toggle unread", "toggle-unread");
            MediaDBView.actionPopUp = button;
        }
        this.actionPopUp = MediaDBView.actionPopUp.cloneNode(true);

        this.remainingElement = document.createElement("div");
        this.remainingElement.className = "remaining";

        this.remainingTimeElement = document.createElement("div");
        this.remainingTimeElement.className = "remaining-time";

        this.progressBarContent = document.createElement("div");
        this.progressBarContent.className = "progress-bar-content";

        this.progressBar = document.createElement("div");
        this.progressBar.className = "progress-bar";

        this.remainingElement.appendChild(this.remainingTimeElement);

        this.progressBarContent.appendChild(this.progressBar);
        this.remainingElement.appendChild(this.progressBarContent);
    },
    appendSubElementsToNode: function(element)
    {
        element.appendChild(this.statusElement);
        element.appendChild(this.thumbnailElement);
        element.appendChild(this.detailElement);
        element.appendChild(this.remainingElement);
        element.appendChild(this.yearElement);
        element.appendChild(this.actionPopUp);
    },

    _unread: false,
    get unread()
    {
        return this._unread;
    },
    set unread(unread)
    {
        if (!unread)
            unread = 0;

        this._unread = unread;
        if (unread)
            this.element.addClassName("not-played");
        else
            this.element.removeClassName("not-played");
    },

    _remainingTime: 0,
    set remainingTime(time)
    {
        if (this._remainingTime == time)
            return;
        if (!time)
            time = 0;
        this._remainingTime = time;
        if (time > 0) {
            this.progressBar.style.width = time * 100 + "%";
            this.element.addClassName("currently-watching");
        }
        else
            this.element.removeClassName("currently-watching");
    },
    get remainingTime()
    {
        return this._remainingTime;
    },

    _currentlyWatching: 0,
    set currentlyWatching(watching)
    {
        this._currentlyWatching = watching;
        if (watching)
            this.element.addClassName("currently-watching");
        else
            this.element.removeClassName("currently-watching");
    },
    get currentlyWatching()
    {
        return this._remainingTime;
    },

    set visible(visible)
    {
        if (this._visible == visible)
            return;

        ListItemView.prototype.__lookupSetter__("visible").call(this, visible);

        if (visible) {
            var options = new Object;
            options["NSNullPlaceholderBindingOption"] = "";

            this.actionPopUp.addEventListener('change', this.actionPopUpChanged.bind(this), false);
            this.actionPopUp.selectedIndex = -1;

            Lunettes.connect(this.nameElement, "textContent", this.cocoaObject, "title");
            Lunettes.connect(this.yearElement, "textContent", this.cocoaObject, "releaseYear", options);
            Lunettes.connect(this.shortSummaryElement, "textContent", this.cocoaObject, "shortSummary", options);
            Lunettes.connect(this, "unread", this.cocoaObject, "unread");
            Lunettes.connect(this, "currentlyWatching", this.cocoaObject, "currentlyWatching");
            Lunettes.connect(this, "remainingTime", this.cocoaObject, "lastPosition");

            options = new Object;
            options["NSValueTransformerNameBindingOption"] = "VLCTimeAsNumberToPrettyTime";
            Lunettes.connect(this.remainingTimeElement, "textContent", this.cocoaObject, "remainingTime", options);
            options = new Object;
            options["NSNullPlaceholderBindingOption"] = "noartwork.png";
            Lunettes.connect(this.thumbnailElement, "src", this.cocoaObject, "artworkURL", options);
        } else {
            Lunettes.unconnect(this.shortSummaryElement, "textContent");
            Lunettes.unconnect(this.yearElement, "textContent");
            Lunettes.unconnect(this.thumbnailElement, "src");
            Lunettes.unconnect(this.remainingTimeElement, "textContent");
            Lunettes.unconnect(this, "remainingTime");
            Lunettes.unconnect(this, "currentlyWatching");
            Lunettes.unconnect(this, "unread");
            Lunettes.unconnect(this.nameElement, "textContent");
        }
    },
    /**
     * When double clicked
     */
    actionPopUpChanged: function(event)
    {
        switch(this.actionPopUp.value) {
            case "remove": {
                var shouldRemove = window.PlatformView.remove(this.cocoaObject, this.parent.arrayController);
                if (shouldRemove)
                this.parent.removeSubview(this);
                break;
            }
            case "toggle-unread": {
                this.cocoaObject.setValueForKey(!this.cocoaObject.valueForKey("unread"), "unread");
                break;
            }
        }

        this.actionPopUp.selectedIndex = -1;

        event.preventDefault();
    },

    /**
     * When double clicked
     */
    action: function()
    {
        window.PlatformView.playCocoaObject(this.cocoaObject);
    }

}
MediaDBView.prototype.__proto__ = MediaView.prototype;
