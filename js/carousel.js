$(document).ready(function() {

    var owl = $('.news_contents');
    owl.owlCarousel({
        margin: 22,
        loop: true,
        items: 3,
        dots: true,
        nav: true,
        navText:["<div class='nav-btn prev-slide'></div>", "<div class='nav-btn next-slide'></div>"],
    });

});