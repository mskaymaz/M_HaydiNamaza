ï»¿var General = function () {

    var controlMenu = 1;

    var init = function () {



    };

    var initEvents = function () {

        // var k = $(window).outerHeight();
        // var c = $(window).innerHeight();
        // var t = $(window).outerHeight(true);


        var is_mobile = false;

        if ($('#mobile-element').css('display') == 'none') {
            is_mobile = true;
        }

        if (is_mobile == true) {

            var windowHeight = $(window).height();
            var minHeight = windowHeight + "px";
            var windowHeight2 = $("#topMenu").height();
            var minHeight2 = windowHeight2 + "px";
            if (minHeight > minHeight2) {
                $('.sidenav').css("min-height", minHeight);
            }
            else {
                $('.sidenav').css("min-height", minHeight2);
            }

            $(".menuHamburger").on("click", function () {
                if (controlMenu == 1) {
                    $(".sidenav").css("display", "none");
                    $("#topMenu").css("display", "none");
                    $(".mobileLogo").css("display", "block");
                    $(".closeMenu").css("display", "block");

                    $(".mainPage").first().css("padding-top", "90px");
                    $(".mobileVideo").css("padding-top", "90px");
                    $(".productsMainPage").css("padding-top", "85px");
                    $(".podcastMainPage").first().css("padding-top", "110px");
                    controlMenu = 0;
                }
                else {
                    $(".sidenav").css("display", "block");
                    $("#topMenu").css("display", "block");
                    $('.sidenav').css("min-height", minHeight);
                    $(".mobileLogo").css("display", "none");
                    $(".closeMenu").css("display", "none");
                    $(".mainPage").first().css("padding-top", "0%");
                    $(".mobileVideo").css("padding-top", "0%");
                    $(".productsMainPage").css("padding-top", "0%");
                    $(".podcastMainPage").first().css("padding-top", "20px");
                    controlMenu = 1;
                }
            });

            if ($(".mobilProductInformation").css("display") == "block") {
                $(".menuHamburger")[0].click();
            }

            $(".podcastMainPage").first().css("padding-top", "20px");

        }



    };


    return {
        init: init,
        initEvents: initEvents,
    }

}();

$(document).ready(function () {

    General.init();
    General.initEvents();


    var urlParams = {};
    $(".searchIcon").on("click", function () {

       // var displayState = $(".searchBox").css("display");
         // $(".searchBox").css("display", "block")
           // $(".searchBox").show();  
        var opacityState = $(".searchBox").css("opacity");
       
        if (opacityState == 0) {
          
            $(".searchBox").css("display", "block")
            $(".searchBox").animate({

                opacity: 1
            }, 500);

            if ($(window).width() < 1000) {
                $("#topMenu").children("li").css("display", "none")
            }
            

        } else {
            urlParams.search = $(".searchBox").val();
            window.location.href = "/Product/Index?" + decodeURIComponent($.param(urlParams));
            $(".searchBox").val('');
        }
    });

    $(".searchBox").keyup(function (event) {
        if (event.keyCode === 13) {
            $(".searchIcon").click();
            $(".searchBox").val('');
        }

    });


    $(".sidenav ul li").each(function () {
     
     var result = $(this).children("a").children(".sidenavCategoryName").text()
     var kes = cut(40, result);
     $(this).children("a").children(".sidenavCategoryName").text(kes)
    });

    function cut(n, text) {
        if (n < text.length) {
            while (text[n] != " " && n > 0) {
                n--;
            }
            text = text.substr(0, n)
            text = text + " ...";
            return text;
        } else {
            return text;
        }

    }


});

