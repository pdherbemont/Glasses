/**
 * @constructor
 */
var PlaylistController = function()
{
    
}

PlaylistController.prototype = {
    init: function()
    {
        window.PlatformView.bindPropertyTo(this, "rootMediaListCount", "rootMediaList.media.@count");
    },

    _rootMediaListCount: 0,
    set rootMediaListCount(newCount)
    {
        // Make sure we don't get undefined
        if (!newCount)
            newCount = 0;
        this._rootMediaListCount = newCount;
        if (newCount > 1)
            this.setShowPlaylistView(true);
    },
    get rootMediaListCount()
    {
        return this._rootMediaListCount;
    },

    setShowPlaylistView:function(show)
    {
        var name = "show-playlist";
        if (show) {
            document.getElementById("more").addClassName("visible");
            document.body.addClassName(name);
        }
        else {
            document.getElementById("more").removeClassName("visible");
            document.body.removeClassName(name);
        }
        if (window.PlatformView.videoDidResize)
            window.PlatformView.videoDidResize();
    },
    togglePlaylistView: function()
    {
        var name = "show-playlist";
        this.setShowPlaylistView(!document.body.hasClassName(name));
    }
}

window.playlistController = new PlaylistController();