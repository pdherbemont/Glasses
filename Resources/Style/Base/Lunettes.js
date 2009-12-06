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
    Escape: 0
};

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
    switch (name)
    {
        case "up":
            break;
        case "down":
            break;
        case "left":
            break;
        case "right":
            break;
        case "down":
            break;
    }
    return false;
}
