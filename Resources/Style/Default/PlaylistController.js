/**
 * @constructor
 */
var PlaylistController = function()
{
}

PlaylistController.prototype = {
    init: function()
    {
        Lunettes.connect(this, "showPlaylist", CocoaObject.windowCocoaObject(), "showPlaylist");
        Lunettes.connect(this, "rootMediaListCount", CocoaObject.documentCocoaObject(), "rootMediaList.media.@count");
    },

    _rootMediaListCount: 0,
    set rootMediaListCount(newCount)
    {
        // Make sure we don't get undefined
        if (!newCount)
            newCount = 0;
        this._rootMediaListCount = newCount;
        if (newCount > 1)
            this.showPlaylist = true;
    },
    get rootMediaListCount()
    {
        return this._rootMediaListCount;
    },

    syncWithAnimation: function()
    {
        this.animationSyncTimer = null;
        window.windowController.videoResized();
        this.animationSyncTimer = window.setTimeout(this.syncWithAnimation.bind(this), 0);
    },

    animationStarted: function()
    {
        // Clear any previous timer.
        if (this.animationSyncTimer)
            window.clearTimeout(this.animationSyncTimer);

        // An animation has started, make sure we correctly
        // resize the VideoView in our backend.
        this.syncWithAnimation();
    },

    animationEnded: function()
    {
        // Stop syncing
        if (this.animationSyncTimer) {
            window.clearTimeout(this.animationSyncTimer);
            this.animationSyncTimer = null;
        }
        window.windowController.videoResized();
    },

    get showPlaylist()
    {
        if (!this._showPlaylist)
            this._showPlaylist = false;
        return this._showPlaylist;
    },
    set showPlaylist(show)
    {
        if (this._showPlaylist == show)
            return;

        Lunettes.willChange(this, "showPlaylist");
        this._showPlaylist = show;
        Lunettes.didChange(this, "showPlaylist");
        var name = "show-playlist";
        var more = document.getElementById("more");
        if (show) {
            if (more)
                more.addClassName("visible");
            document.body.addClassName(name);
            window.windowController.navigationController.currentView.updateVisibleItems();
        }
        else {
            if (more)
                document.getElementById("more").removeClassName("visible");
            document.body.removeClassName(name);
        }

        // Update the video view while we are animating
        this.animationStarted();

        // Stop the animation after the end of the animation
        if (this.animationEndedTimer)
            window.clearTimeout(this.animationEndedTimer);
        this.animationEndedTimer = window.setTimeout(this.animationEnded.bind(this), 230);
    },
    togglePlaylistView: function()
    {
        var name = "show-playlist";
        this.showPlaylist = !document.body.hasClassName(name);
    }
}

window.playlistController = new PlaylistController();
