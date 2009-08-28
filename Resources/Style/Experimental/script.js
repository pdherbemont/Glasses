function togglePlaylistView() {
    var name = "show-playlist";
    if (document.body.className.indexOf(name) == -1)
        document.body.className += " " + name;
    else
        document.body.className = document.body.className.replace(name, "");
}

function tableClicked(event) {
    var object = null;
    if (this.tagName == "TD")
        object = this.parent;
    else if (this.tagName == "TR")
        object = this;
    if (!object)
        return;
    object.className += " selected"
}