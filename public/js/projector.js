var Pageantus = {
    initialize: function(){
        Pageantus.AJAX.setup();
        Pageantus.AJAX.getPageantInformation();
        Pageantus.AJAX.getTime();
        // Pageantus.AJAX.getCategoryID();
        Pageantus.AJAX.getResults();
        Pageantus.bindEvents();
        Pageantus.UI.verticallyCenter('#top-candidates','#content-pane',$('#content-pane').height()-600);
    },
    bindEvents: function(){
        window.oncontextmenu = function(){
            return false;
        };
        window.onresize = function(){
            Pageantus.UI.verticallyCenter('#top-candidates','#content-pane',$('#content-pane').height());
        };
        $('#lock').click(Pageantus.UI.lockScreen);
    }
}

Pageantus.Variables = {
    category: '',
    category_details: {},
    female_candidates: [],
    male_candidates: [],
    get_path: function(desired_path) {
        return $('#server_address').val() + desired_path;
    },
    connected: true
}

Pageantus.UI = {
    listTopFive: function(gender){
        var candidates = [];
        var i;
        if(gender=='m'){
            $('#male').text('');
            candidates = _.sortBy(Pageantus.Variables.male_candidates, function(candidate){return -candidate.average});
            for(i=0;i<5;i++){
                $('#male').append(
                    '<div class="candidate">'
                        +'<span class="image" style="background-image: url(images/pageant/'+
                        candidates[i].candidate_number+'m-face.jpg); ">'
                            +'<span class="male silhouette"></span>'
                           +'<span class="number">'+candidates[i].candidate_number+'</span>'
                        +'</span>'
                        +'<span class="name">'+candidates[i].name+'</span>'
                        +'<span class="score-container">'
                            +'<span class="score-filler" style="width:'+candidates[i].average+'%;"></span>'
                            +'<span class="score-label">'+candidates[i].average+'</span>'
                        +'</span>'
                    +'</div>'
                );
            }
        }
        else if(gender=='f'){
            $('#female').text('');
            // _.sortBy(Pageantus.Variables.female_candidates, function(candidate){return candidate.average});
            candidates = _.sortBy(Pageantus.Variables.female_candidates, function(candidate){return -candidate.average});
            for(i=0;i<5;i++){
                $('#female').append(
                    '<div class="candidate">'
                        +'<span class="image" style="background-image: url(images/pageant/'+
                        candidates[i].candidate_id+'f-face.jpg); ">'
                            +'<span class="female silhouette"></span>'
                            +'<span class="number">'+candidates[i].candidate_number+'</span>'
                        +'</span>'
                        +'<span class="name">'+candidates[i].name+'</span>'
                        +'<span class="score-container">'
                            +'<span class="score-filler" style="width:'+candidates[i].average+'%;"></span>'
                            +'<span class="score-label">'+candidates[i].average+'</span>'
                        +'</span>'
                    +'</div>'
                );
            }
        }
        $('.silhouette').click(function(){
            $(this).fadeOut(400,function(){
                $(this).parent().parent().children('.name').css({'visibility':'visible'});
                $(this).parent().children('.number').css({'visibility':'visible'});
            });
        });
        $('.score-container').click(function(){
            $(this).children('.score-label').fadeIn();
            $(this).children('.score-filler').fadeIn();
        });
    },
    verticallyCenter: function(child, parent, parentHeight, attr){
        var marginTop = 0;
        if(parentHeight==undefined)
            parentHeight = $(parent).innerHeight();
        marginTop = parentHeight/2-$(child).innerHeight()/2;
        if(marginTop<0)
            marginTop = 0;
        switch(attr){
            case 'padding':
                $(parent).css({
                    'padding-top': marginTop+'px'
                    });
                break;
            default:
                $(child).css({
                    'margin-top': marginTop+'px'
                    });
                break;
        }
    }
}

Pageantus.AJAX = {
    setup: function(){
        $.ajaxSetup({
            method: 'GET',
            dataType: 'json',
            error: function(){
                Pageantus.Dialog.show('alert','Server Error','Oops! An error in connection occured.<br />Please try again later.');
                Pageantus.Variables.connected = false;
                $('#connectivity').css('background-position','-26px 0px');
            }
        });
    },
    getPageantInformation: function() {
        $.get(Pageantus.Variables.get_path('active/pageant'), function(data) {
            $('#pageant-name').text(data.long_name);
            $('body').css('background-image', 'url(../images/'+data.background_image+')');
        });
    },
    getResults: function(){
        $.get(Pageantus.Variables.get_path('score/category/M'),
            function(data){
                Pageantus.Variables.male_candidates = data;
                Pageantus.UI.listTopFive('m');
            })
        $.get(Pageantus.Variables.get_path('score/category/F'),
            function(data){
                Pageantus.Variables.female_candidates = data;
                Pageantus.UI.listTopFive('f');
            })
    },
    getTime: function(){
        $.get(Pageantus.Variables.get_path('time'), function(data) {
            $('#time div:eq(0)').text(data.time);
            $('#time div:eq(1)').text(data.date);
            $('#time').fadeIn();
            $('#unlock').fadeIn();
            $('#header span:eq(1)').text(data.time + ' ' + data.meridian);
            Pageantus.Variables.connected = true;
            $('#connectivity').css('background-position', '0px 0px');

        });
        setTimeout(Pageantus.AJAX.getTime, 30000);
    },
    getCategory: function(){
        $.ajax({
            url: Pageantus.Variables.get_path('active/category'),
            success: function(data){
                Pageantus.Variables.category_details = data;
                $('#category-name').text(Pageantus.Variables.category_details.category_name);
                Pageantus.AJAX.getResults();
            }
        });
    },
    getCategoryID: function(){
        $.get(Pageantus.Variables.get_path('active/category'),
                function(data) {
                    console.log()
                    if (data.id != Pageantus.Variables.Current.category.id) {
                        Pageantus.Variables.Current.category = data;
                        Pageantus.AJAX.getCategory();
                    }
                });
    }
}

Pageantus.Dialog = {
    show: function(type,title,message,accept,reject){
        //if an instance of the dialog is already
        //existing,remove it from the DOM
        if($('body').has('#dialogOverlay'))
            $('#dialogOverlay').remove();
        //avoiding undefined event handlers
        if(accept===undefined)
            accept = function(){};
        if(reject===undefined)
            reject = accept;
        if(type===undefined)
            type = '';
        if(title===undefined)
            title = '';
        if(message===undefined)
            message = ''
        //method overloading
        if(arguments.length==1&&arguments[0].constructor==String){
            message = arguments[0];
            title = Pageantus.title;
            type = 'alert';
        }
        else{
            if(type!=='confirm')
                type = 'alert';
            if(title.trim()==='')
                title = Pageantus.title;
            if(message.trim()==='')
                message = '';
        }
        //create dialog box
        $('body').append('<div id="dialogOverlay"><div class="dialogBox"><div class="dialogTitle">'+title+'</div><div class="dialogMessage">'+message+'</div><div class="dialogButtons"></div></div></div>');
        //buttons and event binding
        $('.dialogButtons').append('<input type="button" value="Okay" class="dialogOkay" />');
        $('.dialogOkay').click(function(){
            Pageantus.Dialog.hide(accept);
        });
        if(type==='confirm'){
            $('.dialogButtons').append('<input type="button" value="Cancel" class="dialogCancel" />');
            $('.dialogCancel').click(function(){
                Pageantus.Dialog.hide(reject);
            });
        }
        //fade in dialog box
        $('#dialogOverlay').fadeIn('fast');
        $(".dialogBox").draggable({
            containment:'window'
        });
    },
    hide: function(callback){
        //fade out dialog box
        $('#dialogOverlay').fadeOut('fast');
        //execute callback function if it exists
        if(callback!==null)
            callback();
        //remove dialog elements from the DOM
        setTimeout(function(){
            $('#dialogOverlay').remove();
        },500);
    }
};

$(document).ready(Pageantus.initialize);