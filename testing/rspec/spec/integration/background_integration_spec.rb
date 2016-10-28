require "#{File.dirname(__FILE__)}/../spec_helper"


describe 'Background, Integration' do

  let(:clazz) { CukeModeler::Background }


  describe 'common behavior' do

    it_should_behave_like 'a model, integration'

  end

  describe 'unique behavior' do

    it 'can be instantiated with the minimum viable Gherkin' do
      source = "#{@background_keyword}:"

      expect { clazz.new(source) }.to_not raise_error
    end

    it 'can parse text that uses a non-default dialect' do
      original_dialect = CukeModeler::Parsing.dialect
      CukeModeler::Parsing.dialect = 'en-au'

      begin
        source_text = 'First off: Background name'

        expect { @model = clazz.new(source_text) }.to_not raise_error

        # Sanity check in case modeling failed in a non-explosive manner
        expect(@model.name).to eq('Background name')
      ensure
        # Making sure that our changes don't escape a test and ruin the rest of the suite
        CukeModeler::Parsing.dialect = original_dialect
      end
    end

    it 'stores the original data generated by the parsing adapter', :gherkin4 => true do
      background = clazz.new("#{@background_keyword}: test background\ndescription\n#{@step_keyword} a step")
      data = background.parsing_data

      expect(data.keys).to match_array([:type, :location, :keyword, :name, :steps, :description])
      expect(data[:type]).to eq(:Background)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin3 => true do
      background = clazz.new("#{@background_keyword}: test background\ndescription\n#{@step_keyword} a step")
      data = background.parsing_data

      expect(data.keys).to match_array([:type, :location, :keyword, :name, :steps, :description])
      expect(data[:type]).to eq(:Background)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin2 => true do
      background = clazz.new("#{@background_keyword}: test background\ndescription\n#{@step_keyword} a step")
      data = background.parsing_data

      expect(data.keys).to match_array(['keyword', 'name', 'line', 'description', 'steps', 'type'])
      expect(data['keyword']).to eq('Background')
    end

    it 'provides a descriptive filename when being parsed from stand alone text' do
      source = "bad background text \n #{@background_keyword}:\n #{@step_keyword} a step\n @foo "

      expect { clazz.new(source) }.to raise_error(/'cuke_modeler_stand_alone_background\.feature'/)
    end

    it 'properly sets its child models' do
      source = "#{@background_keyword}: Test background
                  #{@step_keyword} a step"

      background = clazz.new(source)
      step = background.steps.first

      expect(step.parent_model).to equal(background)
    end

    it 'trims whitespace from its source description' do
      source = ["#{@background_keyword}:",
                '  ',
                '        description line 1',
                '',
                '   description line 2',
                '     description line 3               ',
                '',
                '',
                '',
                "  #{@step_keyword} a step"]
      source = source.join("\n")

      background = clazz.new(source)
      description = background.description.split("\n", -1)

      expect(description).to eq(['     description line 1',
                                 '',
                                 'description line 2',
                                 '  description line 3'])
    end


    describe 'getting ancestors' do

      before(:each) do
        source = "#{@feature_keyword}: Test feature

                    #{@background_keyword}: Test background
                      #{@step_keyword} a step"

        file_path = "#{@default_file_directory}/background_test_file.feature"
        File.open(file_path, 'w') { |file| file.write(source) }
      end

      let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
      let(:background) { directory.feature_files.first.feature.background }


      it 'can get its directory' do
        ancestor = background.get_ancestor(:directory)

        expect(ancestor).to equal(directory)
      end

      it 'can get its feature file' do
        ancestor = background.get_ancestor(:feature_file)

        expect(ancestor).to equal(directory.feature_files.first)
      end

      it 'can get its feature' do
        ancestor = background.get_ancestor(:feature)

        expect(ancestor).to equal(directory.feature_files.first.feature)
      end

      it 'returns nil if it does not have the requested type of ancestor' do
        ancestor = background.get_ancestor(:example)

        expect(ancestor).to be_nil
      end

    end


    describe 'model population' do

      context 'from source text' do

        let(:source_text) { "#{@background_keyword}:" }
        let(:background) { clazz.new(source_text) }


        it "models the background's keyword" do
          expect(background.keyword).to eq("#{@background_keyword}")
        end

        it "models the background's source line" do
          source_text = "#{@feature_keyword}:

                           #{@background_keyword}: foo
                             #{@step_keyword} step"
          background = CukeModeler::Feature.new(source_text).background

          expect(background.source_line).to eq(3)
        end

        context 'a filled background' do

          let(:source_text) { "#{@background_keyword}: Background name

                               Background description.

                             Some more.
                                 Even more.

                                 #{@step_keyword} a step
                                 #{@step_keyword} another step" }
          let(:background) { clazz.new(source_text) }


          it "models the background's name" do
            expect(background.name).to eq('Background name')
          end

          it "models the background's description" do
            description = background.description.split("\n", -1)

            expect(description).to eq(['  Background description.',
                                       '',
                                       'Some more.',
                                       '    Even more.'])
          end

          it "models the background's steps" do
            step_names = background.steps.collect { |step| step.text }

            expect(step_names).to eq(['a step', 'another step'])
          end

        end

        context 'an empty background' do

          let(:source_text) { "#{@background_keyword}:" }
          let(:background) { clazz.new(source_text) }


          it "models the background's name" do
            expect(background.name).to eq('')
          end

          it "models the background's description" do
            expect(background.description).to eq('')
          end

          it "models the background's steps" do
            expect(background.steps).to eq([])
          end

        end

      end

    end


    describe 'comparison' do

      it 'is equal to a background with the same steps' do
        source = "#{@background_keyword}:
                    #{@step_keyword} step 1
                    #{@step_keyword} step 2"
        background_1 = clazz.new(source)

        source = "#{@background_keyword}:
                    #{@step_keyword} step 1
                    #{@step_keyword} step 2"
        background_2 = clazz.new(source)

        source = "#{@background_keyword}:
                    #{@step_keyword} step 2
                    #{@step_keyword} step 1"
        background_3 = clazz.new(source)


        expect(background_1).to eq(background_2)
        expect(background_1).to_not eq(background_3)
      end

      it 'is equal to a scenario with the same steps' do
        source = "#{@background_keyword}:
                    #{@step_keyword} step 1
                    #{@step_keyword} step 2"
        background = clazz.new(source)

        source = "#{@scenario_keyword}:
                    #{@step_keyword} step 1
                    #{@step_keyword} step 2"
        scenario_1 = CukeModeler::Scenario.new(source)

        source = "#{@scenario_keyword}:
                    #{@step_keyword} step 2
                    #{@step_keyword} step 1"
        scenario_2 = CukeModeler::Scenario.new(source)


        expect(background).to eq(scenario_1)
        expect(background).to_not eq(scenario_2)
      end

      it 'is equal to an outline with the same steps' do
        source = "#{@background_keyword}:
                    #{@step_keyword} step 1
                    #{@step_keyword} step 2"
        background = clazz.new(source)

        source = "#{@outline_keyword}:
                    #{@step_keyword} step 1
                    #{@step_keyword} step 2
                  #{@example_keyword}:
                    | param |
                    | value |"
        outline_1 = CukeModeler::Outline.new(source)

        source = "#{@outline_keyword}:
                    #{@step_keyword} step 2
                    #{@step_keyword} step 1
                  #{@example_keyword}:
                    | param |
                    | value |"
        outline_2 = CukeModeler::Outline.new(source)


        expect(background).to eq(outline_1)
        expect(background).to_not eq(outline_2)
      end

    end


    describe 'background output' do

      it 'can be remade from its own output' do
        source = "#{@background_keyword}: A background with everything it could have

                  Including a description
                  and then some.

                    #{@step_keyword} a step
                      | value |
                    #{@step_keyword} another step
                      \"\"\"
                      some string
                      \"\"\""
        background = clazz.new(source)

        background_output = background.to_s
        remade_background_output = clazz.new(background_output).to_s

        expect(remade_background_output).to eq(background_output)
      end


      context 'from source text' do

        it 'can output an empty background' do
          source = ["#{@background_keyword}:"]
          source = source.join("\n")
          background = clazz.new(source)

          background_output = background.to_s.split("\n", -1)

          expect(background_output).to eq(["#{@background_keyword}:"])
        end

        it 'can output a background that has a name' do
          source = ["#{@background_keyword}: test background"]
          source = source.join("\n")
          background = clazz.new(source)

          background_output = background.to_s.split("\n", -1)

          expect(background_output).to eq(["#{@background_keyword}: test background"])
        end

        it 'can output a background that has a description' do
          source = ["#{@background_keyword}:",
                    'Some description.',
                    'Some more description.']
          source = source.join("\n")
          background = clazz.new(source)

          background_output = background.to_s.split("\n", -1)

          expect(background_output).to eq(["#{@background_keyword}:",
                                           '',
                                           'Some description.',
                                           'Some more description.'])
        end

        it 'can output a background that has steps' do
          source = ["#{@background_keyword}:",
                    "#{@step_keyword} a step",
                    '|value|',
                    "#{@step_keyword} another step",
                    '"""',
                    'some string',
                    '"""']
          source = source.join("\n")
          background = clazz.new(source)

          background_output = background.to_s.split("\n", -1)

          expect(background_output).to eq(["#{@background_keyword}:",
                                           "  #{@step_keyword} a step",
                                           '    | value |',
                                           "  #{@step_keyword} another step",
                                           '    """',
                                           '    some string',
                                           '    """'])
        end

        it 'can output a background that has everything' do
          source = ["#{@background_keyword}: A background with everything it could have",
                    'Including a description',
                    'and then some.',
                    "#{@step_keyword} a step",
                    '|value|',
                    "#{@step_keyword} another step",
                    '"""',
                    'some string',
                    '"""']
          source = source.join("\n")
          background = clazz.new(source)

          background_output = background.to_s.split("\n", -1)

          expect(background_output).to eq(["#{@background_keyword}: A background with everything it could have",
                                           '',
                                           'Including a description',
                                           'and then some.',
                                           '',
                                           "  #{@step_keyword} a step",
                                           '    | value |',
                                           "  #{@step_keyword} another step",
                                           '    """',
                                           '    some string',
                                           '    """'])
        end

      end


      context 'from abstract instantiation' do

        let(:background) { clazz.new }


        it 'can output a background that has only steps' do
          background.steps = [CukeModeler::Step.new]

          expect { background.to_s }.to_not raise_error
        end

      end

    end

  end

end
