/**
 * An Episode View
 * @constructor
 * @extends ListItemView
 * @param {CocoaObject} cocoaObject
 * @param {Object} parent
 * @param {string} elementTag
 */
var EpisodeView = function(cocoaObject, parent, elementTag)
{
    ListItemView.call(this, cocoaObject, parent, elementTag);
    this.element.addClassName("episode-view");
}


EpisodeView.prototype = {
    createSubElements: function()
    {
        if (!EpisodeView.actionPopUp) {
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
            EpisodeView.actionPopUp = button;
        }
        this.actionPopUp = EpisodeView.actionPopUp.cloneNode(true);

        this.nameElement = document.createElement("div");
        this.nameElement.className = "name";
        this.seasonNumberElement = document.createElement("div");
        this.seasonNumberElement.className = "season-number";
        this.episodeNumberElement = document.createElement("div");
        this.episodeNumberElement.className = "episode-number";

        this.statusElement = document.createElement("div");
        this.statusElement.className = "status";
    },

    appendSubElementsToNode: function(element)
    {
        element.appendChild(this.statusElement);
        element.appendChild(this.nameElement);
        element.appendChild(this.seasonNumberElement);
        element.appendChild(this.episodeNumberElement);
        element.appendChild(this.actionPopUp);
    },

    set visible(visible)
    {
        if (this._visible == visible)
            return;

        ListItemView.prototype.__lookupSetter__("visible").call(this, visible);

        if (visible) {
            this.actionPopUp.addEventListener('change', this.actionPopUpChanged.bind(this), false);
            this.actionPopUp.selectedIndex = -1;
            var opts = this.actionPopUp.children;
            for (var opt in opts)
                opt.selected = false;

            Lunettes.connect(this, "unread", this.cocoaObject, "unread");

            var options = Lunettes.NullPlaceHolder("Untitled");
            Lunettes.connect(this.nameElement, "textContent", this.cocoaObject, "name", options);

            options = Lunettes.NullPlaceHolder("-");
            Lunettes.connect(this.episodeNumberElement, "textContent", this.cocoaObject, "episodeNumber", options);

            options = Lunettes.NullPlaceHolder("-");
            Lunettes.connect(this.seasonNumberElement, "textContent", this.cocoaObject, "seasonNumber", options);
        } else {
            this.actionPopUp.removeEventListener('change', this.actionPopUpChanged.bind(this), false);

            Lunettes.unconnect(this, "unread");
            Lunettes.unconnect(this.seasonNumberElement, "textContent");
            Lunettes.unconnect(this.episodeNumberElement, "textContent");
            Lunettes.unconnect(this.nameElement, "textContent");
        }
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
        var opts = this.actionPopUp.children;
        for (var opt in opts)
            opt.selected = false;

        event.preventDefault();
    },
    action: function()
    {
        window.PlatformView.playCocoaObject(this.cocoaObject);
    }
}

EpisodeView.prototype.__proto__ = ListItemView.prototype;

/**
 * A TV Show View
 * @constructor
 * @extends ListItemView
 * @param {CocoaObject} cocoaObject
 * @param {Object} parent
 * @param {string} elementTag
 */
var TVShowView = function(cocoaObject, parent, elementTag)
{
    ListItemView.call(this, cocoaObject, parent, elementTag);
    this.element.addClassName("tv-show-view");
}


TVShowView.prototype = {
    createSubElements: function()
    {
        this.descriptionElement = document.createElement("div");
        this.descriptionElement.className = "description";

        this.nameElement = document.createElement("div");
        this.nameElement.className = "name";
//        this.yearElement = document.createElement("div");
//        this.yearElement.className = "year";
        this.unreadCountElement = document.createElement("div");
        this.unreadCountElement.className = "unread-count";
        this.thumbnailElement = document.createElement("img");
        this.thumbnailElement.className = "thumbnail";

        /* Episodes */
        this.episodeThumbnailElement = document.createElement("img");
        this.episodeThumbnailElement.className = "thumbnail";
        this.episodeSummaryElement = document.createElement("div");
        this.episodeSummaryElement.className = "short-summary";

        this.selectedEpisodeElement = document.createElement("div");
        this.selectedEpisodeElement.className = "selected-episode";

        this.selectedEpisodeElement.appendChild(this.episodeThumbnailElement);
        this.selectedEpisodeElement.appendChild(this.episodeSummaryElement);

        this.episodesListElement = document.createElement("div");

        this.episodesElement = document.createElement("div");
        this.episodesElement.className = "episodes";

        this.episodesElement.appendChild(this.selectedEpisodeElement);
        this.episodesElement.appendChild(this.episodesListElement);

    },

    appendSubElementsToNode: function(element)
    {
        this.descriptionElement.appendChild(this.thumbnailElement);
        this.descriptionElement.appendChild(this.nameElement);
        //this.descriptionElement.appendChild(this.yearElement);
        this.descriptionElement.appendChild(this.unreadCountElement);

        element.appendChild(this.descriptionElement);
        element.appendChild(this.episodesElement);
    },

    set visible(visible)
    {
        if (this._visible == visible)
            return;

        ListItemView.prototype.__lookupSetter__("visible").call(this, visible);

        if (visible) {
            this.descriptionElement.addEventListener('click', this.mouseClicked.bind(this), false);

            var options = Lunettes.NullPlaceHolder("noartwork.png");
            Lunettes.connect(this.thumbnailElement, "src", this.cocoaObject, "artworkURL", options);

            options = Lunettes.NullPlaceHolder("Untitled");
            Lunettes.connect(this.nameElement, "textContent", this.cocoaObject, "name");

//            options = Lunettes.NullPlaceHolder("");
//            Lunettes.connect(this.yearElement, "textContent", this.cocoaObject, "releaseYear", options);

            //options = Lunettes.NullPlaceHolder("No Summary");
            //Lunettes.connect(this.shortSummaryElement, "textContent", this.cocoaObject, "shortSummary", options);
            Lunettes.connect(this, "unreadEpisodeCount", this.cocoaObject, "unreadEpisodes.@count");

            // Episodes
            options = Lunettes.NullPlaceHolder("");
            Lunettes.connect(this.episodeThumbnailElement, "src", this, "episodes.arrayController.backendObject.selection.artworkURL", options);
            options = Lunettes.NullPlaceHolder("No Summary");
            Lunettes.connect(this.episodeSummaryElement, "textContent", this, "episodes.arrayController.backendObject.selection.shortSummary", options);


        } else {
            this.descriptionElement.removeEventListener('click', this.mouseClicked.bind(this), false);

            Lunettes.unconnect(this.episodeSummaryElement, "textContent");
            Lunettes.unconnect(this.episodeThumbnailElement, "src");

            Lunettes.unconnect(this.thumbnailElement, "src");
            Lunettes.unconnect(this, "unreadEpisodeCount");
            //Lunettes.unconnect(this.shortSummaryElement, "textContent");
            //Lunettes.unconnect(this.yearElement, "textContent");
            Lunettes.unconnect(this.nameElement, "textContent");
        }
    },

    _unreadEpisodeCount: 0,
    set unreadEpisodeCount(unreadEpisodeCount)
    {
        if (!unreadEpisodeCount)
            unreadEpisodeCount = 0;
        Lunettes.willChange(this, "unreadEpisodeCount");
        this._unreadEpisodeCount = unreadEpisodeCount;
        Lunettes.didChange(this, "unreadEpisodeCount");

        this.unreadCountElement.textContent = unreadEpisodeCount;
        if (unreadEpisodeCount == 0)
            this.unreadCountElement.addClassName("zero-unread");
        else
            this.unreadCountElement.removeClassName("zero-unread");
    },
    get unreadEpisodeCount()
    {
        return this._unreadEpisodeCount;
    },

    _episodes: null,
    set episodes(episodes)
    {
        if (!episodes)
            episodes = null;
        Lunettes.willChange(this, "episodes");
        this._episodes = episodes;
        Lunettes.didChange(this, "episodes");
    },
    get episodes()
    {
        return this._episodes;
    },
    /**
     * Event Handler
     * @param {Event} event
     */
    mouseClicked: function(event)
    {
        console.log("clicked " + event);
        console.log("clicked " + this.element.className + " " + this.element.hasClassName("disclosed"));
        if (this.element.hasClassName("disclosed"))
            this.element.removeClassName("disclosed");
        else {
            if (!this.episodes) {
                var episodes = new ListView(this.cocoaObject, "episodes", EpisodeView);
                episodes._noVisibleItemOptimization = true; // We don't yet optimize which one we display or not.
                episodes.createArrayController();
                Lunettes.connect(episodes, "arrayController.backendObject.sortDescriptors", CocoaObject.windowCocoaObject(), "tvShowEpisodesSortDescriptors");
                Lunettes.connect(episodes, "arrayController.backendObject.filterPredicate", CocoaObject.windowCocoaObject(), "predicateThatFiltersShowEpisodeWithoutFile");
                episodes.attach(this.episodesElement);
                this.episodes = episodes;
            }

            this.element.addClassName("disclosed");
        }
        event.stopPropagation();

    },

    /**
     * Event Handler
     * @param {Event} event
     */
    mouseDown: function(event)
    {
        // Probably highlight/select
        return;
    }
}

TVShowView.prototype.__proto__ = ListItemView.prototype;

/**
 * TV Shows List View
 * @constructor
 * @extends ListView
 * @param {CocoaObject} cocoaObject
 * @param {string} subItemsKeyPath
 * @param {Element} elementTag
 */
var TVShowsListView = function(cocoaObject, subItemsKeyPath, elementTag)
{
    ListView.call(this, cocoaObject, subItemsKeyPath, TVShowView, elementTag);
    this.element.addClassName("tv-shows-list-view");
    this.displayName = "TVShowsListView";
}

TVShowsListView.prototype = {
    select: function(item)
    {

    }
}
TVShowsListView.prototype.__proto__ = ListView.prototype;
