$(document).ready(function() {

  var channel, pusher;
  Pusher.log = function(message) {
    if (window.console && window.console.log) {
      window.console.log(message);
      window.console.log(window.location.href);
    }
  };

  function pusherKey(){
    var event_number = $('#pusher-key').text();
    return event_number;
  }

  pusher = new Pusher(pusherKey(), {
    encrypted: true
  });

  channel = pusher.subscribe('vote_count_channel');
  return channel.bind('new_message', function(data) {
    choiceVotebuilder(data);
  });
});

  function choiceVotebuilder(data){
    var choice = data.choice_id;
    var choice = "#choice_" + choice.toString();
    console.log(choice);
    $(choice + ' .vote-count').text("Votes: " + data.vote_count);
    $(choice + ' .progress-bar').attr('style', "width: " + (data.vote_count * 3) + "%");
  };
