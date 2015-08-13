if ( typeof Dynamocles == "undefined" ) {
    Dynamocles = {};
}
if ( typeof Dynamocles.App == "undefined" ) {
    Dynamocles.App = {};
}

Dynamocles.App.Comment = function ( selector ) {
    var form = document.createElement( 'form' );

    form.innerHTML = '<label>Name:</label><input type="text" name="author_name" />' +
                    '<label>E-mail:</label><input type="email" name="author_email" />' +
                    '<label>Website:</label><input type="url" name="author_website" />' +
                    '<textarea name="content"></textarea>' +
                    '<button>Submit</button>';

    var container = document.querySelector( selector );
    if ( !container ) {
        throw( 'Comment container "' + selector + '" not found' );
    }

    container.appendChild( form );

    // TODO: Also add current comments

};

