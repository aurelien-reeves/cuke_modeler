require "#{File.dirname(__FILE__)}/../../spec_helper"


describe 'Example, Integration' do

  let(:clazz) { CukeModeler::Example }
  let(:example) { clazz.new }
  let(:minimum_viable_gherkin) { "#{EXAMPLE_KEYWORD}:" }
  let(:maximum_viable_gherkin) do
    "@a_tag
     #{EXAMPLE_KEYWORD}: test example

     Example
     description

       | param   |
       | value 1 |
       | value 2 |"
  end


  describe 'common behavior' do

    it_should_behave_like 'a model, integration'

  end

  describe 'unique behavior' do

    it 'can be instantiated with the minimum viable Gherkin' do
      expect { @model = clazz.new(minimum_viable_gherkin) }.to_not raise_error
    end

    it 'can parse text that uses a non-default dialect' do
      original_dialect = CukeModeler::Parsing.dialect
      CukeModeler::Parsing.dialect = 'en-au'

      begin
        source_text = "You'll wanna:
                           | param |
                           | value |"

        expect { @model = clazz.new(source_text) }.to_not raise_error

        # Sanity check in case modeling failed in a non-explosive manner
        expect(@model.rows.first.cells.first.value).to eq('param')
      ensure
        # Making sure that our changes don't escape a test and ruin the rest of the suite
        CukeModeler::Parsing.dialect = original_dialect
      end
    end

    describe 'parsing data' do

      context 'with minimum viable Gherkin' do

        let(:source_text) { minimum_viable_gherkin }

        it 'stores the original data generated by the parsing adapter' do
          example = clazz.new(source_text)
          data = example.parsing_data

          expect(data.keys).to match_array([:location, :keyword, :name])
          expect(data[:keyword]).to eq(EXAMPLE_KEYWORD)
        end

      end

      context 'with maximum viable Gherkin' do

        let(:source_text) { maximum_viable_gherkin }

        it 'stores the original data generated by the parsing adapter' do
          example = clazz.new(source_text)
          data = example.parsing_data

          expect(data.keys).to match_array([:tags, :location, :keyword, :name, :table_header, :table_body, :description])
          expect(data[:name]).to eq('test example')
        end

      end

    end

    it 'provides a descriptive filename when being parsed from stand alone text' do
      source = 'bad example text'

      expect { clazz.new(source) }.to raise_error(/'cuke_modeler_stand_alone_example\.feature'/)
    end

    it 'trims whitespace from its source description' do
      source = ["#{EXAMPLE_KEYWORD}:",
                '  ',
                '        description line 1',
                '',
                '   description line 2',
                '     description line 3               ',
                '',
                '',
                '',
                '|param|',
                '|value|']
      source = source.join("\n")

      example = clazz.new(source)
      description = example.description.split("\n", -1)

      expect(description).to eq(['     description line 1',
                                 '',
                                 'description line 2',
                                 '  description line 3'])
    end


    describe 'model population' do

      context 'from source text' do

        let(:source_text) { "#{EXAMPLE_KEYWORD}:" }
        let(:example) { clazz.new(source_text) }


        it "models the example's keyword" do
          expect(example.keyword).to eq("#{EXAMPLE_KEYWORD}")
        end

        it "models the example's source line" do
          source_text = "#{FEATURE_KEYWORD}:

                           #{OUTLINE_KEYWORD}:
                             #{STEP_KEYWORD} step
                           #{EXAMPLE_KEYWORD}:
                             | param |
                             | value |"
          example = CukeModeler::Feature.new(source_text).tests.first.examples.first

          expect(example.source_line).to eq(5)
        end


        context 'a filled example' do

          let(:source_text) { "@tag1 @tag2 @tag3
                               #{EXAMPLE_KEYWORD}: test example

                                   Some example description.

                                 Some more.
                                     Even more.

                                 | param |
                                 | value |" }
          let(:example) { clazz.new(source_text) }


          it "models the example's name" do
            expect(example.name).to eq('test example')
          end

          it "models the example's description" do
            description = example.description.split("\n", -1)

            expect(description).to eq(['  Some example description.',
                                       '',
                                       'Some more.',
                                       '    Even more.'])
          end

          it "models the example's rows" do
            row_cell_values = example.rows.collect { |row| row.cells.collect { |cell| cell.value } }

            expect(row_cell_values).to eq([['param'], ['value']])
          end

          it "models the example's tags" do
            tag_names = example.tags.collect { |tag| tag.name }

            expect(tag_names).to eq(['@tag1', '@tag2', '@tag3'])
          end

          it "models the example's parameters" do
            expect(example.parameters).to eq(['param'])
          end

        end

        context 'an empty example' do

          let(:source_text) { "#{EXAMPLE_KEYWORD}:" }
          let(:example) { clazz.new(source_text) }


          it "models the example's name" do
            expect(example.name).to eq('')
          end

          it "models the example's description" do
            expect(example.description).to eq('')
          end

          it "models the example's rows" do
            expect(example.rows).to eq([])
          end

          it "models the example's tags" do
            expect(example.tags).to eq([])
          end

        end

      end

    end


    it 'properly sets its child models' do
      source = "@a_tag
                #{EXAMPLE_KEYWORD}:
                  | param   |
                  | value 1 |"

      example = clazz.new(source)
      rows = example.rows
      tag = example.tags.first

      expect(rows[0].parent_model).to equal(example)
      expect(rows[1].parent_model).to equal(example)
      expect(tag.parent_model).to equal(example)
    end

    it 'does not include the parameter row when accessing argument rows' do
      source = "#{EXAMPLE_KEYWORD}:\n|param1|param2|\n|value1|value2|\n|value3|value4|"
      example = clazz.new(source)

      rows = example.argument_rows
      row_cell_values = rows.collect { |row| row.cells.collect { |cell| cell.value } }

      expect(row_cell_values).to eq([['value1', 'value2'], ['value3', 'value4']])
    end

    it 'does not include argument rows when accessing the parameter row' do
      source = "#{EXAMPLE_KEYWORD}:\n|param1|param2|\n|value1|value2|\n|value3|value4|"
      example = clazz.new(source)

      row = example.parameter_row
      row_cell_values = row.cells.collect { |cell| cell.value }

      expect(row_cell_values).to eq(['param1', 'param2'])
    end


    describe 'adding rows' do

      it 'can add a new row as a hash, string values' do
        source = "#{EXAMPLE_KEYWORD}:\n|param1|param2|\n|value1|value2|"
        example = clazz.new(source)

        new_row = {'param1' => 'value3', 'param2' => 'value4'}
        example.add_row(new_row)
        row_cell_values = example.argument_rows.collect { |row| row.cells.collect { |cell| cell.value } }

        expect(row_cell_values).to eq([['value1', 'value2'], ['value3', 'value4']])
      end

      it 'can add a new row as a hash, non-string values' do
        source = "#{EXAMPLE_KEYWORD}:\n|param1|param2|\n|value1|value2|"
        example = clazz.new(source)

        new_row = {:param1 => 'value3', 'param2' => 4}
        example.add_row(new_row)
        row_cell_values = example.argument_rows.collect { |row| row.cells.collect { |cell| cell.value } }

        expect(row_cell_values).to eq([['value1', 'value2'], ['value3', '4']])
      end

      it 'can add a new row as a hash, random key order' do
        source = "#{EXAMPLE_KEYWORD}:\n|param1|param2|\n|value1|value2|"
        example = clazz.new(source)

        new_row = {'param2' => 'value4', 'param1' => 'value3'}
        example.add_row(new_row)
        row_cell_values = example.argument_rows.collect { |row| row.cells.collect { |cell| cell.value } }

        expect(row_cell_values).to eq([['value1', 'value2'], ['value3', 'value4']])
      end

      it 'can add a new row as an array, string values' do
        source = "#{EXAMPLE_KEYWORD}:\n|param1|param2|\n|value1|value2|"
        example = clazz.new(source)

        new_row = ['value3', 'value4']
        example.add_row(new_row)
        row_cell_values = example.argument_rows.collect { |row| row.cells.collect { |cell| cell.value } }

        expect(row_cell_values).to eq([['value1', 'value2'], ['value3', 'value4']])
      end

      it 'can add a new row as an array, non-string values' do
        source = "#{EXAMPLE_KEYWORD}:\n|param1|param2|param3|\n|value1|value2|value3|"
        example = clazz.new(source)

        new_row = [:value4, 5, 'value6']
        example.add_row(new_row)
        row_cell_values = example.argument_rows.collect { |row| row.cells.collect { |cell| cell.value } }

        expect(row_cell_values).to eq([['value1', 'value2', 'value3'], ['value4', '5', 'value6']])
      end

      it 'can only use a Hash or an Array to add a new row' do
        source = "#{EXAMPLE_KEYWORD}:\n|param|\n|value|"
        example = clazz.new(source)

        expect { example.add_row({}) }.to_not raise_error
        expect { example.add_row([]) }.to_not raise_error
        expect { example.add_row(:a_row) }.to raise_error(ArgumentError)
      end

      it 'trims whitespace from added rows' do
        source = "#{EXAMPLE_KEYWORD}:\n|param1|param2|\n|value1|value2|"
        example = clazz.new(source)

        hash_row = {'param1' => 'value3  ', 'param2' => '  value4'}
        array_row = ['value5', ' value6 ']
        example.add_row(hash_row)
        example.add_row(array_row)
        row_cell_values = example.argument_rows.collect { |row| row.cells.collect { |cell| cell.value } }

        expect(row_cell_values).to eq([['value1', 'value2'], ['value3', 'value4'], ['value5', 'value6']])
      end

      it 'will complain if a row is added and no parameters have been set' do
        example = clazz.new
        example.rows = []

        new_row = ['value1', 'value2']
        expect { example.add_row(new_row) }.to raise_error('Cannot add a row. No parameters have been set.')

        new_row = {'param1' => 'value1', 'param2' => 'value2'}
        expect { example.add_row(new_row) }.to raise_error('Cannot add a row. No parameters have been set.')
      end

      it 'does not modify its row input' do
        source = "#{EXAMPLE_KEYWORD}:\n|param1|param2|\n|value1|value2|"
        example = clazz.new(source)

        array_row = ['value1'.freeze, 'value2'.freeze].freeze
        expect { example.add_row(array_row) }.to_not raise_error

        hash_row = {'param1'.freeze => 'value1'.freeze, 'param2'.freeze => 'value2'.freeze}.freeze
        expect { example.add_row(hash_row) }.to_not raise_error
      end

    end


    describe 'removing rows' do

      it 'can remove an existing row as a hash' do
        source = "#{EXAMPLE_KEYWORD}:\n|param1|param2|\n|value1|value2|\n|value3|value4|"
        example = clazz.new(source)

        old_row = {'param1' => 'value3', 'param2' => 'value4'}
        example.remove_row(old_row)
        row_cell_values = example.argument_rows.collect { |row| row.cells.collect { |cell| cell.value } }

        expect(row_cell_values).to eq([['value1', 'value2']])
      end

      it 'can remove an existing row as a hash, random key order' do
        source = "#{EXAMPLE_KEYWORD}:\n|param1|param2|\n|value1|value2|\n|value3|value4|"
        example = clazz.new(source)

        old_row = {'param2' => 'value4', 'param1' => 'value3'}
        example.remove_row(old_row)
        row_cell_values = example.argument_rows.collect { |row| row.cells.collect { |cell| cell.value } }

        expect(row_cell_values).to eq([['value1', 'value2']])
      end

      it 'can remove an existing row as an array' do
        source = "#{EXAMPLE_KEYWORD}:\n|param1|param2|\n|value1|value2|\n|value3|value4|"
        example = clazz.new(source)

        old_row = ['value3', 'value4']
        example.remove_row(old_row)
        row_cell_values = example.argument_rows.collect { |row| row.cells.collect { |cell| cell.value } }

        expect(row_cell_values).to eq([['value1', 'value2']])
      end

      it 'can only use a Hash or an Array to remove an existing row' do
        expect { example.remove_row({}) }.to_not raise_error
        expect { example.remove_row([]) }.to_not raise_error
        expect { example.remove_row(:a_row) }.to raise_error(ArgumentError)
      end

      it 'trims whitespace from removed rows' do
        source = "#{EXAMPLE_KEYWORD}:\n|param1|param2|\n|value1|value2|\n|value3|value4|\n|value5|value6|"
        example = clazz.new(source)

        # These will affect different rows
        hash_row = {'param1' => 'value3  ', 'param2' => '  value4'}
        array_row = ['value5', ' value6 ']

        example.remove_row(hash_row)
        example.remove_row(array_row)
        row_cell_values = example.argument_rows.collect { |row| row.cells.collect { |cell| cell.value } }

        expect(row_cell_values).to eq([['value1', 'value2']])
      end

      it 'can gracefully remove a row from an example that has no rows' do
        example = clazz.new
        example.rows = []

        expect { example.remove_row({}) }.to_not raise_error
        expect { example.remove_row([]) }.to_not raise_error
      end

      it 'will not remove the parameter row' do
        source = "#{EXAMPLE_KEYWORD}:\n|param1|param2|\n|value1|value2|"
        example = clazz.new(source)

        hash_row = {'param1' => 'param1', 'param2' => 'param2'}
        array_row = ['param1', 'param2']

        example.remove_row(hash_row)
        row_cell_values = example.rows.collect { |row| row.cells.collect { |cell| cell.value } }

        expect(row_cell_values).to eq([['param1', 'param2'], ['value1', 'value2']])

        example.remove_row(array_row)
        row_cell_values = example.rows.collect { |row| row.cells.collect { |cell| cell.value } }

        expect(row_cell_values).to eq([['param1', 'param2'], ['value1', 'value2']])
      end

      it 'will remove an argument row that is the same as the parameter row' do
        source = "#{EXAMPLE_KEYWORD}:\n|param1|param2|\n|value1|value2|\n|param1|param2|"
        example = clazz.new(source)

        hash_row = {'param1' => 'param1', 'param2' => 'param2'}
        array_row = ['param1', 'param2']

        example.remove_row(hash_row)
        row_cell_values = example.rows.collect { |row| row.cells.collect { |cell| cell.value } }

        expect(row_cell_values).to eq([['param1', 'param2'], ['value1', 'value2']])

        example.remove_row(array_row)
        row_cell_values = example.rows.collect { |row| row.cells.collect { |cell| cell.value } }

        expect(row_cell_values).to eq([['param1', 'param2'], ['value1', 'value2']])
      end

    end


    describe 'getting ancestors' do

      before(:each) do
        CukeModeler::FileHelper.create_feature_file(:text => source_gherkin, :name => 'example_test_file', :directory => test_directory)
      end


      let(:test_directory) { CukeModeler::FileHelper.create_directory }
      let(:source_gherkin) { "#{FEATURE_KEYWORD}: Test feature

                              #{OUTLINE_KEYWORD}: Test test
                                #{STEP_KEYWORD} a step
                              #{EXAMPLE_KEYWORD}: Test example
                                | a param |
                                | a value |"
      }

      let(:directory_model) { CukeModeler::Directory.new(test_directory) }
      let(:example_model) { directory_model.feature_files.first.feature.tests.first.examples.first }


      it 'can get its directory' do
        ancestor = example_model.get_ancestor(:directory)

        expect(ancestor).to equal(directory_model)
      end

      it 'can get its feature file' do
        ancestor = example_model.get_ancestor(:feature_file)

        expect(ancestor).to equal(directory_model.feature_files.first)
      end

      it 'can get its feature' do
        ancestor = example_model.get_ancestor(:feature)

        expect(ancestor).to equal(directory_model.feature_files.first.feature)
      end

      context 'an example that is part of an outline' do

        let(:test_directory) { CukeModeler::FileHelper.create_directory }
        let(:source_gherkin) { "#{FEATURE_KEYWORD}: Test feature

                                  #{OUTLINE_KEYWORD}: Test outline
                                    #{STEP_KEYWORD} a step
                                  #{EXAMPLE_KEYWORD}:
                                    | param |
                                    | value |"
        }

        let(:directory_model) { CukeModeler::Directory.new(test_directory) }
        let(:example_model) { directory_model.feature_files.first.feature.tests.first.examples.first }


        it 'can get its outline' do
          ancestor = example_model.get_ancestor(:outline)

          expect(ancestor).to equal(directory_model.feature_files.first.feature.tests.first)
        end

      end

      it 'returns nil if it does not have the requested type of ancestor' do
        ancestor = example_model.get_ancestor(:example)

        expect(ancestor).to be_nil
      end

    end


    describe 'example output' do

      it 'can be remade from its own output' do
        source = "@tag1 @tag2 @tag3
                  #{EXAMPLE_KEYWORD}: with everything it could have

                  Some description.
                  Some more description.

                    | param1 | param2 |
                    | value1 | value2 |
                    | value3 | value4 |"
        example = clazz.new(source)

        example_output = example.to_s
        remade_example_output = clazz.new(example_output).to_s

        expect(remade_example_output).to eq(example_output)
      end


      # This behavior should already be taken care of by the cell object's output method, but
      # the example object has to adjust that output in order to properly buffer column width
      # and it is possible that during that process it messes up the cell's output.

      it 'can correctly output a row that has special characters in it' do
        source = ["#{EXAMPLE_KEYWORD}:",
                  '  | param with \| |',
                  '  | a value with \| and \\\\ |',
                  '  | a value with \\\\ |']
        source = source.join("\n")
        example = clazz.new(source)

        example_output = example.to_s.split("\n", -1)

        expect(example_output).to eq(["#{EXAMPLE_KEYWORD}:",
                                      '  | param with \|          |',
                                      '  | a value with \| and \\\\ |',
                                      '  | a value with \\\\        |'])
      end


      context 'from source text' do

        it 'can output an empty example' do
          source = ["#{EXAMPLE_KEYWORD}:"]
          source = source.join("\n")
          example = clazz.new(source)

          example_output = example.to_s.split("\n", -1)

          expect(example_output).to eq(["#{EXAMPLE_KEYWORD}:"])
        end

        it 'can output an example that has a name' do
          source = ["#{EXAMPLE_KEYWORD}: test example"]
          source = source.join("\n")
          example = clazz.new(source)

          example_output = example.to_s.split("\n", -1)

          expect(example_output).to eq(["#{EXAMPLE_KEYWORD}: test example"])
        end

        it 'can output an example that has a description' do
          source = ["#{EXAMPLE_KEYWORD}:",
                    'Some description.',
                    'Some more description.']
          source = source.join("\n")
          example = clazz.new(source)

          example_output = example.to_s.split("\n", -1)

          expect(example_output).to eq(["#{EXAMPLE_KEYWORD}:",
                                        '',
                                        'Some description.',
                                        'Some more description.'])
        end

        it 'can output an example that has a single row' do
          source = ["#{EXAMPLE_KEYWORD}:",
                    '|param1|param2|']
          source = source.join("\n")
          example = clazz.new(source)

          example_output = example.to_s.split("\n", -1)

          expect(example_output).to eq(["#{EXAMPLE_KEYWORD}:",
                                        '  | param1 | param2 |'])
        end

        it 'can output an example that has multiple rows' do
          source = ["#{EXAMPLE_KEYWORD}:",
                    '|param1|param2|',
                    '|value1|value2|',
                    '|value3|value4|']
          source = source.join("\n")
          example = clazz.new(source)

          example_output = example.to_s.split("\n", -1)

          expect(example_output).to eq(["#{EXAMPLE_KEYWORD}:",
                                        '  | param1 | param2 |',
                                        '  | value1 | value2 |',
                                        '  | value3 | value4 |'])
        end

        it 'can output an example that has tags' do
          source = ['@tag1',
                    '@tag2 @tag3',
                    "#{EXAMPLE_KEYWORD}:",
                    '|param1|param2|',
                    '|value1|value2|',
                    '|value3|value4|']
          source = source.join("\n")
          example = clazz.new(source)

          example_output = example.to_s.split("\n", -1)

          expect(example_output).to eq(['@tag1 @tag2 @tag3',
                                        "#{EXAMPLE_KEYWORD}:",
                                        '  | param1 | param2 |',
                                        '  | value1 | value2 |',
                                        '  | value3 | value4 |'])
        end

        it 'can output an example that has everything' do
          source = ['@tag1',
                    '@tag2 @tag3',
                    "#{EXAMPLE_KEYWORD}: with everything it could have",
                    'Some description.',
                    'Some more description.',
                    '|param1|param2|',
                    '|value1|value2|',
                    '|value3|value4|']
          source = source.join("\n")
          example = clazz.new(source)

          example_output = example.to_s.split("\n", -1)

          expect(example_output).to eq(['@tag1 @tag2 @tag3',
                                        "#{EXAMPLE_KEYWORD}: with everything it could have",
                                        '',
                                        'Some description.',
                                        'Some more description.',
                                        '',
                                        '  | param1 | param2 |',
                                        '  | value1 | value2 |',
                                        '  | value3 | value4 |'])
        end

        it 'buffers row cells based on the longest value in a column' do
          source = "#{EXAMPLE_KEYWORD}:
                    |parameter 1| x|
                    |y|value 1|
                    |a|b|"
          example = clazz.new(source)

          example_output = example.to_s.split("\n", -1)

          expect(example_output).to eq(["#{EXAMPLE_KEYWORD}:",
                                        '  | parameter 1 | x       |',
                                        '  | y           | value 1 |',
                                        '  | a           | b       |'])
        end

      end


      context 'from abstract instantiation' do

        let(:example) { clazz.new }


        it 'can output an example that has only tags' do
          example.tags = [CukeModeler::Tag.new]

          expect { example.to_s }.to_not raise_error
        end

        it 'can output an example that has only rows' do
          example.rows = [CukeModeler::Row.new]

          expect { example.to_s }.to_not raise_error
        end

      end

    end

  end

end
