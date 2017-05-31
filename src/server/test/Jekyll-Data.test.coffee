Jekyll_Data = require '../src/Jekyll-Data'

describe 'Jekyll_Data', ->

  jekyll_Data = null

  beforeEach ->
    jekyll_Data = new Jekyll_Data()
    using jekyll_Data,->
      @.participants_Data     ._keys().size().assert_Is_Bigger_Than 140
      @.working_Sessions_Data ._keys().size().assert_Is_Bigger_Than 140
      @.topics_Data._keys()   .size().assert_Is_Bigger_Than 7

  it 'constructor', ->
    using jekyll_Data, ->
      @.folder_Root        .assert_Folder_Exists()
      @.folder_Data        .assert_Folder_Exists()
      @.folder_Data_Mapped .assert_Folder_Exists()
      @.folder_Participants.assert_Folder_Exists()

  it 'map_Participant_Raw_Data', ->
    using jekyll_Data, ->
      test_Data = @.folder_Participants.files_Recursive().first().file_Contents()
      using @.map_Participant_Raw_Data(test_Data), ->
        @._keys().assert_Contains ['title','type','image']
        @['working-sessions'].size().assert_Bigger_Than 4

  it 'map_Participants_Data', ->
    using jekyll_Data, ->
      @.file_Json_Participants.file_Delete()
      data = @.map_Participants_Data()
      data._keys().size().add(4).assert_Is @.folder_Participants.files_Recursive().size()      # if these don't match it means that there are duplicate file names (the extra 4 are the template)
                                .assert_Bigger_Than(100)                                       # ensure that we have at least 100 mappings
      using data['Daniel Miessler'], ->
        @.metadata.layout.assert_Is 'blocks/page-participant'

      @.file_Json_Participants.assert_File_Exists()

  it 'map_Tracks_Data', ->
    using jekyll_Data, ->
      data = @.map_Tracks_Data()
      data._keys().size().assert_Is_12

  it 'map_Topics_Data', ->
    using jekyll_Data, ->
      data = @.map_Topics_Data()
      data._keys().size().assert_Is 8


  it 'map_Working_Sessions_Data', ->
    using jekyll_Data, ->
      data = @.map_Working_Sessions_Data()
      data._keys().size().assert_Is_Bigger_Than 100

  it 'resolve_Names', ->
    using jekyll_Data, ->
      test_Names        = ['Bernhard Mueller' , 'Sven Schleier','Abc']
      @.resolve_Names test_Names
           .assert_Is [ { name: 'Bernhard Mueller', url: '/Participants/ticket-24h-owasp/Bernhard-Mueller.html' , remote:false},
                        { name: 'Sven Schleier'   ,url: '/Participants/funded/Sven-Schleier.html'               , remote:false},
                        { name: 'Abc' } ]

  it 'resolve_Related_To',->
    using jekyll_Data, ->
      name                  = 'Education'
      @.resolve_Related_To name
        .assert_Contains ['NodeGoat', 'Juice Shop']

  it 'resolve_Topics', ->
    using jekyll_Data, ->
      topics_Data = @.file_Json_Topics.load_Json()
      test_Names        = ['SOC' , 'GDPR','Abc']
      @.resolve_Topics(topics_Data, test_Names)
          .assert_Is [ { name: 'SOC' , url: '/Working-Sessions/Technologies/SOC.html'  },
                       { name: 'GDPR', url: '/Working-Sessions/Technologies/GDPR.html' },
                       { name: 'Abc'                                                   }]


  it 'resolve_Working_Sessions', ->
    using jekyll_Data, ->
      working_Sessions_Data = @.file_Json_Working_Sessions.load_Json()
      test_Names        = ['Juice Shop','NodeGoat','Abc']
      @.resolve_Working_Sessions(working_Sessions_Data, test_Names)
          .assert_Is [ { name: 'Juice Shop', url: '/Working-Sessions/Owasp-Projects/Juice-Shop.html' },
                       { name: 'NodeGoat'  , url: '/Working-Sessions/Owasp-Projects/NodeGoat.html' },
                       { name: 'Abc' } ]



  it.only 'working_Session', ->
    name = 'A10 - Underprotected APIs'
    using jekyll_Data.working_Session(name), ->
      @.name.assert_Is name

  # bugs

  it 'bug - related-to not showing in Education Track', ->
    using jekyll_Data, ->
      name      = 'Education'
      tracks    = @.map_Tracks_Data()
      education = tracks[name]
      education['related-to'].assert_Is_Not []                          # this was wrong

      first_Mapping = @.resolve_Related_To(name).assert_Contains 'Juice Shop'
      final_Mapping = @.resolve_Working_Sessions(first_Mapping).assert_Is_Not []        # bug was inside this function
      final_Mapping[0].assert_Is { name: 'Juice Shop', url: '/Working-Sessions/Owasp-Projects/Juice-Shop.html' }

  it.only 'bug -  related-to not showing in Securing Legacy Applications', ->
    using jekyll_Data, ->
      using @.working_Session('Securing Legacy Applications'), ->
        @['related-to'].size().assert_Is 3                          # this is working
