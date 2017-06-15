require "test_helper"
require "shellwords"

class TsRoutesTest < Minitest::Test

  def dir
    File.expand_path("build", __dir__)
  end

  def tsc(source)
    ts_file = Tempfile.new(['routes', '.ts'])
    ts_file.write(source)

    output = `$(npm bin)/tsc --strict #{Shellwords.escape(ts_file.path)} 2>&1`
    ts_file.delete
    output
  end

  def app_source
    <<~TS
      // this is generated in #{Time.now} by #{__FILE__}
      // DO NOT EDIT THIS FILE.

      import * as Routes from "./routes";

      console.log(Routes.entriesPath());
      console.log(Routes.entriesPath({ page: 1, per: 20 }));
      console.log(Routes.entryPath(10, { format: 'json' }));
      console.log(Routes.entryPath(10, { anchor: 'foo bar baz' }));
    TS
  end

  def test_version
    refute_nil ::TsRoutes::VERSION
  end

  def test_smoke
    source = TsRoutes::Generator.new(exclude: [/admin_/]).generate

    File.write("#{dir}/routes.ts", source)
    File.write("#{dir}/app.ts", app_source)

    assert system("node_modules/.bin/tsc", "--strict", "#{dir}/app.ts")
    assert_equal <<~'TEXT', `node #{Shellwords.escape(dir) + "/app.js"}`
      /entries
      /entries?page=1&per=20
      /entries/10.json
      /entries/10#foo%20bar%20baz
    TEXT
  end
end
