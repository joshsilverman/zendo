/* class declarations */

var cDoc = Class.create({

    reviewer: null,
    progressBar: null,

    initialize: function() {

        /* new reviewer */
        var data = $('card_json').innerHTML.evalJSON();
        console.log(data);
        this.reviewer = new cReviewer(data);

        /* resize listener - fire after dom:loaded */
        window.onresize = this.onResize;
        this.onResize();
        AppUtilities.resizeContents.delay(.01);
    },

    onResize: function() {

        /* vertically center cards */
        var footer = $('footer');
        var footerY = footer.getHeight();
        var viewportY = document.viewport.getHeight();
        var title = $('title');
        var titleY = title.getHeight();
        var titlerOffsetY = title.cumulativeOffset()[1];

        var maxContentsY = viewportY - titlerOffsetY - footerY;
        var extraY = maxContentsY - 502;

        var titleMargin = extraY / 2;
        if (titleMargin > 0) $('title').setStyle({'marginTop': titleMargin + 'px'})

        /* place footer */
        AppUtilities.resizeContents();
    }
});

var cReviewer = Class.create({

    progressBar: null,
    reviewHandlers: null,

    grade_4: 9,
    grade_3: 6,
    grade_2: 4,
    grade_1: 1,

    cards: [],
    currentCardIndex: 0,

    initialize: function(data) {

        /* load cards */
        data.each(function(cardData) {
            this.cards.push(new cCard(cardData['term']));
        }.bind(this));

        /* show first */
        if (this.cards[0]) this.cards[0].cue();
        else $('card_front').update("<i>No cards to review</i>");
        
        /* next listeners */
        $('grade_4').observe('click', this.next.bind(this, this.grade_4));
        $('grade_3').observe('click', this.next.bind(this, this.grade_3));
        $('grade_2').observe('click', this.next.bind(this, this.grade_2));
        $('grade_1').observe('click', this.next.bind(this, this.grade_1));

        /* nav listeners */
        $('back_button').observe('click', this.back.bind(this, false));
//        $('next_button').observe('click', this.next.bind(this, false));
        $('next_button').observe('click',function(){
            if(doc.reviewer.cards[doc.reviewer.currentCardIndex].phase == 1){
                doc.reviewer.next(9);
            }
        }.bind(this));

        /* review handlers */
        this.reviewHandlers = new cReviewHandlers();

        /* progress bar */
        //this.progressBar = new cProgressBar();
        $('progress_fraction').update("1/"+this.cards.length);
    },

    next: function(grade) {

        /* grade current */
        if (grade) {
            var card = this.cards[this.currentCardIndex];
            card.grade(grade);
            if(card.response==null){
                card.response = grade;
            }
        /* If no grade, card was skipped => post high confidence / zero importance for now */
        } else {
            var requestUrl = '/mems/update/'+this.cards[this.currentCardIndex].memId+'/9/0';
            new Ajax.Request(requestUrl, {
                onSuccess: function() {},

                onFailure: function() {},

                onComplete: function() {}
//                onComplete: function(transport) {}//$('log').update(transport.responseText);}
            });
        }
        if (this.cards.length >= (this.currentCardIndex)) this.currentCardIndex++;

        /* advance */
        if (this.cards[this.currentCardIndex]) {
            if (this.cards[this.currentCardIndex].confidence == -1)
                this.cards[this.currentCardIndex].cue();
            else this.cards[this.currentCardIndex].showAll();
            //this.progressBar.update(this.currentCardIndex, this.cards.length);

            /* update progress bar */
            if (this.currentCardIndex <= this.cards.length) {
                //this.progressBar.update(this.currentCardIndex, this.cards.length);
                $('progress_fraction').update(this.currentCardIndex+1+"/"+this.cards.length);

            }
        }
        else {

            //this.progressBar.update(this.currentCardIndex, this.cards.length);
            this.currentCardIndex--;

            //Hide grade buttons.
            $$('.button_container, .grade_yourself').each(function (buttonContainer) {buttonContainer.addClassName('grade_hide')});

            //Set grade values here (got it: count, kinda: count, etc..)
            var gradeHash = new Hash();
            gradeHash.set(this.grade_4, 0);
            gradeHash.set(this.grade_3, 0);
            gradeHash.set(this.grade_2, 0);
            gradeHash.set(this.grade_1, 0);
            var score = 0;

            //Collect confidence of each card.
            this.cards.each( function(card) {
                //Skips ungraded cards.
                if (card.confidence > 0) {
                    gradeHash.set(card.confidence, (gradeHash.get(card.confidence) + 1));
                    score = score + card.confidence;
                }
            });

            //Prevent chart page when no cards were reviewed
            if (score <= 0) {
                alert("No more cards to review!");
            } else {

                //Largest value in hash times # of cards
                var total = 9 * this.cards.length;
                var chartURL = "http://chart.apis.google.com/chart?chf=bg,s,F5F5F500&chs=500x225&cht=p3&chco=16BE16|7FE97F|FD6666|E03838&chd=t:"
                    + gradeHash.get(this.grade_4) + "," + gradeHash.get(this.grade_3) + "," + gradeHash.get(this.grade_2) + "," + gradeHash.get(this.grade_1) +
                    "&chdl=Got%20it+-+" + gradeHash.get(this.grade_4) + "|Kinda+-+" + gradeHash.get(this.grade_3) +
                    "|Barely+-+" + gradeHash.get(this.grade_2) + "|No%20clue+-+" + gradeHash.get(this.grade_1) + "&chma=|2"

                $('card_front').update("Your score: <h1>" + Math.round((score/total)*100) + "%</h1>");
                $('card_back').update("<img src=" + chartURL + "></img>");
                $('grade_container').setStyle({'display':'none'});
                $('card_show').setStyle({'display':'none'});
                $('summary').setStyle({'display':'block'});

            }
        }
    },

    back: function() {

        /* check boundary */
        if (this.currentCardIndex == 0) return;

        /* back */
        this.currentCardIndex--;
        if (this.cards[this.currentCardIndex]) {
            var card = this.cards[this.currentCardIndex];
            if(card.response == null){
                card.cue();
            } else if(card.phase==2){
                if(card.mc){card.mc_show();}
                else if(card.fita){card.fita_show();}
                else {card.showAll();}
            } else if(card.phase==3){
                if(card.fita){card.fita_show();}
                else{card.showAll();}
            } else {card.showAll();}

            console.log("response:" + card.response);

            $('summary').setStyle({'display':'none'});
        }
        else if (this.currentCardIndex > 0){
            this.currentCardIndex++;
        }

        /* update progress bar */
        $('progress_fraction').update(this.currentCardIndex+1+"/"+this.cards.length);

        //this.progressBar.update(this.currentCardIndex, this.cards.length);
    },

    displayGrade: function(grade) {

        /* remove all chosen classnames */
        $$(".grade button").each(function(element) {
            element.removeClassName('chosen');
        })

        /* display grade */
        if (grade == this.grade_4) $("grade_4").addClassName("chosen");
        else if (grade == this.grade_3) $("grade_3").addClassName("chosen");
        else if (grade == this.grade_2) $("grade_2").addClassName("chosen");
        else if (grade == this.grade_1) $("grade_1").addClassName("chosen");
    }
});

var cReviewHandlers = Class.create({

    initialize: function() {
        console.log("rh init");
        document.observe("keydown", this.delegateKeystrokeHandler.bind(this));
    },

    delegateKeystrokeHandler: function(event) {

        /* no special event handling if in a text area */
        if (event.target.nodeName == "TEXTAREA") return;

        switch (event.keyCode) {
//            case (13):
//                this.onEnter(event);
//                break;
            case (32):
                this.onSpace(event);
                break;
            case (37):
                this.onLeft(event);
                break;
//            case (38):
//                this.onUp(event);
//                break;
            case (39):
                this.onRight(event);
                break;
//            case (40):
//                this.onDown(event);
//                break;
            case (52):
                this.on4(event);
                break;
            case (51):
                this.on3(event);
                break;
            case (50):
                this.on2(event);
                break;
            case (49):
                this.on1(event);
                break;

            default:
                console.log(event.keyCode);
        }
    },

    onSpace: function(event) {
        /* show card sides */
        if(doc.reviewer.cards[doc.reviewer.currentCardIndex].phase == 4){
            doc.reviewer.cards[doc.reviewer.currentCardIndex].showAll();
        }
        event.stop();
    },

    onLeft: function(event) {
        doc.reviewer.back();
        event.stop();
    },

    onRight: function(event) {
//        var requestUrl = '/mems/update/'+this.memId+'/'+this.confidence+'/'+this.importance;
//        new Ajax.Request(requestUrl, {
//            onSuccess: function() {},
//
//            onFailure: function() {},
//
//            onComplete: function(transport) {}//$('log').update(transport.responseText);}
//        });
        if(doc.reviewer.cards[doc.reviewer.currentCardIndex].phase == 1){
            doc.reviewer.next(9);
            event.stop();
        } else {
            doc.reviewer.next();
            event.stop();
        }
    },

    onUp: function(event) {

        /* increment current card's grade and display */
        var card = doc.reviewer.cards[doc.reviewer.currentCardIndex];
        card.increment();
        doc.reviewer.displayGrade(card.confidence);
        event.stop();
    },

    onDown: function(event) {

        /* decrement current card's grade and display */
        var card = doc.reviewer.cards[doc.reviewer.currentCardIndex];
        card.decrement();
        doc.reviewer.displayGrade(card.confidence);
        event.stop();
    },

    onEnter: function() {

        /* invoke next with current card's confidence */
        doc.reviewer.next(doc.reviewer.cards[doc.reviewer.currentCardIndex].confidence);
    },

    on4: function() {
        if(doc.reviewer.cards[doc.reviewer.currentCardIndex].phase == 4){
            doc.reviewer.displayGrade(doc.reviewer.grade_4);
            (function () {
                $$('.button_container, .grade_yourself').each(function (buttonContainer) {buttonContainer.addClassName('grade_hide')});
                doc.reviewer.displayGrade(-1);
                doc.reviewer.next(doc.reviewer.grade_4);
            }).delay(.4);
        }
    },

    on3: function() {
        if(doc.reviewer.cards[doc.reviewer.currentCardIndex].phase == 4){
            doc.reviewer.displayGrade(doc.reviewer.grade_3);
            (function () {
                $$('.button_container, .grade_yourself').each(function (buttonContainer) {buttonContainer.addClassName('grade_hide')});
                doc.reviewer.displayGrade(-1);
                doc.reviewer.next(doc.reviewer.grade_3);
            }).delay(.4);
        }
    },

    on2: function() {
        if(doc.reviewer.cards[doc.reviewer.currentCardIndex].phase == 4){
            doc.reviewer.displayGrade(doc.reviewer.grade_2);
            (function () {
                $$('.button_container, .grade_yourself').each(function (buttonContainer) {buttonContainer.addClassName('grade_hide')});
                doc.reviewer.displayGrade(-1);
                doc.reviewer.next(doc.reviewer.grade_2);
            }).delay(.4);
        }
    },

    on1: function() {
        if(doc.reviewer.cards[doc.reviewer.currentCardIndex].phase == 4){
            doc.reviewer.displayGrade(doc.reviewer.grade_1);
            (function () {
                doc.reviewer.displayGrade(-1);
                $$('.button_container, .grade_yourself').each(function (buttonContainer) {buttonContainer.addClassName('grade_hide')});
                doc.reviewer.next(doc.reviewer.grade_1);
            }).delay(.4);
        }
    }
});

var cCard = Class.create({

    /* out of ten for easy url  */
    importance: 8,
    confidence: -1,
    phase: null,
    level: null,
    memId: null,
    front: '',
    back: '',
    question: null,
    answers: null,
    mc: false,
    fita: false,
    response: null,

    buttons: '<div id="edit_buttons">\
                <button id="button_edit" class="edit" style="display:none">Edit</button>\
                <button id="button_done" class="done" style="display:none">Done</button>\
                <button id="button_cancel" class="cancel" style="display:none">X</button>\
              </div>',
    
    initialize: function(data) {
        this.memId = data['mems'][0]['id'];
        this.front = data['name'];
        this.back = data['definition'];
        this.phase = data['phase'];
        if(data['questions'].length > 0){
            this.question = data['questions'][0]['question'];
            //this.fita = true;     //keep false always until we've tested MC'
            if(data['answers'].length>2){
                this.mc = true;

                var randomArray = [];

                for(var i=0; i<3; i++){
                    randomArray[i] = data['answers'][i]['answer'];
                }
                randomArray[data['answers'].length] = this.front;

                this.answers=[];
                var i = 0;
                while(i<4){
                    var rando = Math.floor(Math.random()*randomArray.length)
                    var ans = randomArray[rando];
                    if(ans != null){
                        this.answers[i] = ans;
                        randomArray[rando] = null;
                        i++;
                    }
                }
            }
        }
//        if(data['mems'][0]['strength']<20){
//            this.phase = 3;
//            if(data['mems'][0]['strength']<10){
//                this.phase = 2;
//                if(data['mems'][0]['strength']<5){
//                    this.phase = 1;
//                }
//            }
//        }else{this.phase = 4;}
//
//        //HARD CODE THE PHASE FOR TESTING PURPOSES//
        this.phase = 2;

    },

    cue: function(){
        console.log(this.phase);
        switch(this.phase){
            case (1):
                this.cue_p1();
                break;
            case (2):
                if(this.mc){
                    this.cue_p2();
                }else if(this.fita){
                    this.cue_p3();
                }else{
                    this.cue_p4();
                }
                break;
            case (3):
                if(this.fita){
                    this.cue_p3();
                }else{
                    this.cue_p4();
                }
                break;
            case (4):
                this.cue_p4();
                break;
            default:
                console.log("There was an error evaluating the phase");

        }
    },

    cue_p1: function() {
        /* Learning Card */

        /* front */
        $('card_front').update("<div id='card_front_text'>"+this.front+"</div>" + this.buttons);
        $('card_front_text').update(this.front);

        /* back */
        $('card_back').update("<div id='card_back_text'>"+this.back+"</div>");
        $('card_back_text').update(this.back);

        $('card_show').stopObserving('click');
        $('card_show').update("Review This Concept");

        /* hide grade buttons */
        $$('.button_container, .grade_yourself').each(function (buttonContainer) {
            buttonContainer.addClassName('grade_hide');
            var button = buttonContainer.down("button");
            if (button) {
                button.removeClassName('chosen');
            }
        });
        $('grade_container').setStyle({'display':'none'});
        $('card_show').setStyle({'display':'block'});
//        $$('.arrows_up_down')[0].hide();
    },

    cue_p2: function() {
        /* Multiple Choice */

        /* front */
        $('card_front').update("<div id='card_front_text'>"+this.question+"</div>" + this.buttons);
        $('card_front_text').update(this.question);

        /* back */
        
        $('card_back').update("<div id='mc_container'><div id='mc_a'>"+this.answers[0]+"</div>\
                                <div id='mc_b'>"+this.answers[1]+"</div>\
                                <div id='mc_c'>"+this.answers[2]+"</div>\
                                <div id='mc_d'>"+this.answers[3]+"</div>\
                                </div>");

        $('card_show').stopObserving('click');
        $('card_show').update("Click or Press Letter to Choose An Answer");

        /* hide grade buttons */
        $$('.button_container, .grade_yourself').each(function (buttonContainer) {
            buttonContainer.addClassName('grade_hide');
            var button = buttonContainer.down("button");
            if (button) {
                button.removeClassName('chosen');
            }
        });
        $('grade_container').setStyle({'display':'none'});
        $('card_show').setStyle({'display':'block'});
//        $$('.arrows_up_down')[0].hide();

        $('mc_a').stopObserving('click');
        $('mc_b').stopObserving('click');
        $('mc_c').stopObserving('click');
        $('mc_d').stopObserving('click');

        $('mc_a').observe('click', function(){this.mc_grade($('mc_a'));}.bind(this));
        $('mc_b').observe('click', function(){this.mc_grade($('mc_b'));}.bind(this));
        $('mc_c').observe('click', function(){this.mc_grade($('mc_c'));}.bind(this));
        $('mc_d').observe('click', function(){this.mc_grade($('mc_d'));}.bind(this));
    },

    cue_p3: function() {
        /* Fill in the Answer */

        /* front */
        $('card_front').update("<div id='card_front_text'>"+this.question+"</div>" + this.buttons);
        $('card_front_text').update(this.question);

        /* back */
        $('card_back').update('___________');

        $('card_show').stopObserving('click');
        $('card_show').update("Fill in the Answer");

        /* hide grade buttons */
        $$('.button_container, .grade_yourself').each(function (buttonContainer) {
            buttonContainer.addClassName('grade_hide');
            var button = buttonContainer.down("button");
            if (button) {
                button.removeClassName('chosen');
            }
        });
        $('grade_container').setStyle({'display':'none'});
        $('card_show').setStyle({'display':'block'});
//        $$('.arrows_up_down')[0].hide();
    },

    cue_p4: function() {
        /* Flash card*/
        
        /* front */
        $('card_front').update("<div id='card_front_text'>"+this.front+"</div>" + this.buttons);
        $('card_front_text').update(this.front);

        /* back */
        $('card_back').update('');

        $('card_show').stopObserving('click', this.showAll);
        $('card_show').observe('click', this.showAll.bind(this));
        $('card_show').update("Spacebar or Click Here to Flip");

        /* hide grade buttons */
        $$('.button_container, .grade_yourself').each(function (buttonContainer) {
            buttonContainer.addClassName('grade_hide');
            var button = buttonContainer.down("button");
            if (button) {
                button.removeClassName('chosen');
            }
        });
        $('grade_container').setStyle({'display':'none'});
        $('card_show').setStyle({'display':'block'});
//        $$('.arrows_up_down')[0].hide();
    },

    showAll: function() {
        /* show */
        $('card_front').update("<div id='card_front_text'></div>");
//        $('card_front').update("<div id='card_front_text'></div>" + this.buttons);
        $('card_front_text').update(this.front);
        console.log(this.back);
        $('card_back').update( "<div id='card_back_text'>"+this.back+"</div>");

        /* show grading buttons */
        $('grade_container').setStyle({'display':'block'});
        $$('.button_container, .grade_yourself').each(function (buttonContainer) {buttonContainer.removeClassName('grade_hide')});
//        $$('.arrows_up_down')[0].show();

        /*hide show bar*/
        $('card_show').setStyle({'display':'none'});
        /* set grade associated with current card */
        doc.reviewer.displayGrade(doc.reviewer.cards[doc.reviewer.currentCardIndex].confidence);

        $('grade_4').setStyle({'background':'url("../../images/reviewer/got-it.png")'});
        $('grade_3').setStyle({'background':'url("../../images/reviewer/kinda.png")'});
        $('grade_2').setStyle({'background':'url("../../images/reviewer/barely.png")'});
        $('grade_1').setStyle({'background':'url("../../images/reviewer/no-clue.png")'});

        if(this.confidence==9){$('grade_4').setStyle({'background':'url("../../images/reviewer/got-it-hover.png")'});}
        if(this.confidence==6){$('grade_3').setStyle({'background':'url("../../images/reviewer/kinda-hover.png")'});}
        if(this.confidence==4){$('grade_2').setStyle({'background':'url("../../images/reviewer/barely-hover.png")'});}
        if(this.confidence==1){$('grade_1').setStyle({'background':'url("../../images/reviewer/no-clue-hover.png")'});}
        /* edit button and listener */
//        $('button_edit').observe('click', this.makeEditable.bind(this));
//        $('button_edit').show();
    },

    grade: function(grade) {

        /* set confidence */
        this.confidence = grade

        /* save grade */
        var requestUrl = '/mems/update/'+this.memId+'/'+this.confidence+'/'+this.importance;
        new Ajax.Request(requestUrl, {
            onSuccess: function() {},
            
            onFailure: function() {},

            onComplete: function(transport) {console.log('mem updated')}//$('log').update(transport.responseText);}
        });
    },

    mc_grade: function(choice){

        console.log(choice);
        console.log(this.front);
        this.response = choice.innerHTML;
        $('mc_a').stopObserving('click');
        $('mc_b').stopObserving('click');
        $('mc_c').stopObserving('click');
        $('mc_d').stopObserving('click');

        if(choice.innerHTML == this.front){
            choice.setStyle({'background-color':'green'});
            this.grade(9);
        }else{
            this.grade(1);
            choice.setStyle({'background-color':'red'});
            if($('mc_a').innerHTML == this.front){
                $('mc_a').setStyle({'background-color':'green'});
            }
            if($('mc_b').innerHTML == this.front){
                $('mc_b').setStyle({'background-color':'green'});
            }
            if($('mc_c').innerHTML == this.front){
                $('mc_c').setStyle({'background-color':'green'});
            }
            if($('mc_d').innerHTML == this.front){
                $('mc_d').setStyle({'background-color':'green'});
            }
        }

    },

    mc_show: function(){
        /* Multiple Choice */

        /* front */
        $('card_front').update("<div id='card_front_text'>"+this.question+"</div>" + this.buttons);
        $('card_front_text').update(this.question);

        /* back */

        $('card_back').update("<div id='mc_container'><div id='mc_a'>"+this.answers[0]+"</div>\
                                <div id='mc_b'>"+this.answers[1]+"</div>\
                                <div id='mc_c'>"+this.answers[2]+"</div>\
                                <div id='mc_d'>"+this.answers[3]+"</div>\
                                </div>");

        $('card_show').stopObserving('click');
        $('card_show').update("Click or Press Letter to Choose An Answer");

        /* hide grade buttons */
        $$('.button_container, .grade_yourself').each(function (buttonContainer) {
            buttonContainer.addClassName('grade_hide');
            var button = buttonContainer.down("button");
            if (button) {
                button.removeClassName('chosen');
            }
        });
        $('grade_container').setStyle({'display':'none'});
        $('card_show').setStyle({'display':'block'});
        console.log(this.response);
        var choice;
        if($('mc_a').innerHTML == this.response){choice = $('mc_a');}
        else if($('mc_b').innerHTML == this.response){choice = $('mc_b');}
        else if($('mc_c').innerHTML == this.response){choice = $('mc_c');}
        else {choice = $('mc_d');}

        if(this.response == this.front){
            choice.setStyle({'background-color':'green'});
        }else{
            choice.setStyle({'background-color':'red'});
            if($('mc_a').innerHTML == this.front){
                $('mc_a').setStyle({'background-color':'green'});
            }
            if($('mc_b').innerHTML == this.front){
                $('mc_b').setStyle({'background-color':'green'});
            }
            if($('mc_c').innerHTML == this.front){
                $('mc_c').setStyle({'background-color':'green'});
            }
            if($('mc_d').innerHTML == this.front){
                $('mc_d').setStyle({'background-color':'green'});
            }
        }

    },
    
    fita_grade: function(){
        console.log("fita_grade called");
    },

    fita_show: function() {
        console.log("fita_show called");
    },

    increment: function() {

        if (this.confidence == doc.reviewer.grade_3) this.confidence = doc.reviewer.grade_4;
        else if (this.confidence == doc.reviewer.grade_2) this.confidence = doc.reviewer.grade_3;
        else if (this.confidence == doc.reviewer.grade_1) this.confidence = doc.reviewer.grade_2;
    },

    decrement: function() {

        if (this.confidence == doc.reviewer.grade_4) this.confidence = doc.reviewer.grade_3;
        else if (this.confidence == doc.reviewer.grade_3) this.confidence = doc.reviewer.grade_2;
        else if (this.confidence == doc.reviewer.grade_2) this.confidence = doc.reviewer.grade_1;
    }
});

/* global objects */
document.observe('dom:loaded', function() {
    
    //parser = new cParser(); //@todo move to doc object
    doc = new cDoc();

    /* fire app:loaded */
    document.fire('app:loaded');

    /* observe push enable */
    Event.observe($("mobile_review"), "click", function(e) {
        var requestUrl = "/documents/enable_mobile/" + $('card_json').innerHTML.evalJSON()[0]['line']['document_id'] + "/" + (($("mobile_review").checked)?1:0);
        //TODO fill callback parameters
        new Ajax.Request(requestUrl, {
            onSuccess : function(e) {
                if (e.responseText == "fail") {
                    console.log("No mobile device associated with account!");
                    $("mobile_review").checked = false;
                    alert("Looks like you don't have a mobile device enabled yet! To enable push review, you need to" +
                          " download the StudyEgg app to your smartphone and sign in using your email and password. " +
                          " If you believe you have received this message in error, please contact us!");
                } else {
                    console.log("Mobile device found.");
                }
            }
        });
    }.bind(this));
});


