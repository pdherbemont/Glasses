/*
 * Forward declaration of WebKit's console.
 */
var console;

/*
 * Our namespace.
 */

var Lunettes = new Object();
window.Lunettes = Lunettes;

/**
 * Keys.
 */
Lunettes.EventKey = {
    DownArrow: 40,
    RightArrow: 39,
    UpArrow: 38,
    LeftArrow: 37,
    Enter: 13,
    Escape: 27
};

window.remoteButtonHandlerIsInPlaylistMode = false;

/**
 * This method is called by the core when the remote button was pressed.
 * This default behaviour is to handle nothing.
 *
 * Some style may want to overload it.
 *
 * @param {string} name
 * @return {boolean} wheter the event was handled
 */
window.remoteButtonHandler = function (name)
{
    /**
     * @type {NavigationController}
     */
    var navigationController = window.windowController.navigationController;
    if (!navigationController)
        return false;

    var currentMediaListView = navigationController.currentView;
    if (!currentMediaListView)
        return false;

    // For now let the backend handle the remote when there is no
    // playlist.
    if (currentMediaListView.subitemsCount <= 1 )
        return false;

    window.remoteButtonHandlerIsInPlaylistMode = document.body.hasClassName("show-playlist");

    if (name == "menu") {
        window.remoteButtonHandlerIsInPlaylistMode = !window.remoteButtonHandlerIsInPlaylistMode;
        window.playlistController.showPlaylist = window.remoteButtonHandlerIsInPlaylistMode;
        return true;
    }

    if (!window.remoteButtonHandlerIsInPlaylistMode)
        return false;

    switch (name)
    {
        case "up":
            currentMediaListView.selectPrevious();
            currentMediaListView.scrollToSelection();
            return true;
        case "down":
            currentMediaListView.selectNext();
            currentMediaListView.scrollToSelection();
            return true;
        case "left":
            if (navigationController.hasElementToPop())
                navigationController.pop();
            return true;
        case "right":
        case "middle":
            currentMediaListView.selection[0].action();
            window.playlistController.showPlaylist = false;
            return true;
    }
    return false;
}

Lunettes.NullPlaceHolder = function (a)
{
    var options = new Object;
    options["NSNullPlaceholderBindingOption"] = a;
    return options;
}
