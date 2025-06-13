# See perf.rake for details on how to run benchmarks
# Sample command:
#   BENCHMARKING_ENABLED=true RAILS_ENV=production ENDPOINT=/ rake benchmark:ips
namespace :benchmark do
  # When to use: Track overall endpoint speed improvements over time (recommended, most practical test)
  desc "Run cold & warm performance benchmarks and append to history"
  task ips: :environment do
    path = ENV.fetch("ENDPOINT", "/")

    # 🚫 Fail fast unless the benchmark is run in production mode
    unless Rails.env.production?
      raise "benchmark:ips must be run with RAILS_ENV=production (current: #{Rails.env})"
    end

    # ---------------------------------------------------------------------------
    # Tunable parameters – override with environment variables if needed
    # ---------------------------------------------------------------------------
    cold_warmup     = Integer(ENV.fetch("COLD_WARMUP", 0))  # seconds to warm up before *cold* timing (0 == true cold)
    cold_iterations = Integer(ENV.fetch("COLD_ITERATIONS", 1)) # requests to measure for the cold run

    warm_warmup     = Integer(ENV.fetch("WARM_WARMUP", 5))  # seconds benchmark-ips uses to stabilise JIT/caches
    warm_time       = Integer(ENV.fetch("WARM_TIME", 30))   # seconds benchmark-ips samples for warm statistics
    # ---------------------------------------------------------------------------

    setup_benchmark_env(path)
    FileUtils.mkdir_p("tmp/benchmarks")

    timestamp  = Time.current.strftime("%Y-%m-%d %H:%M:%S")
    commit_sha = `git rev-parse --short HEAD 2>/dev/null`.strip rescue "unknown"
    puts "🕒 Starting benchmark run at #{timestamp} (#{commit_sha})"

    # 🚿  Flush application caches so the first request is a *true* cold hit
    Rails.cache&.clear if defined?(Rails)

    # ---------------------------
    # 1️⃣  Cold measurement
    # ---------------------------
    puts "❄️  Running cold benchmark for #{path} (#{cold_iterations} iteration)..."
    cold_cmd = "IPS_WARMUP=#{cold_warmup} IPS_TIME=0 IPS_ITERATIONS=#{cold_iterations} " \
               "bundle exec derailed exec perf:ips"
    cold_output = `#{cold_cmd} 2>&1`
    cold_result = extract_clean_results(cold_output)

    # ---------------------------
    # 2️⃣  Warm measurement
    # ---------------------------
    puts "🔥 Running warm benchmark for #{path} (#{warm_time}s sample)..."
    warm_cmd = "IPS_WARMUP=#{warm_warmup} IPS_TIME=#{warm_time} " \
               "bundle exec derailed exec perf:ips"
    warm_output = `#{warm_cmd} 2>&1`
    warm_result = extract_clean_results(warm_output)

    # ---------------------------------------------------------------------------
    # Persist results
    # ---------------------------------------------------------------------------
    separator        = "\n" + "=" * 70 + "\n"
    timestamp_header = "#{separator}📊 BENCHMARK RUN - #{timestamp} (#{commit_sha})#{separator}"

    # Table header
    table_header    = "| Type | IPS | Deviation | Time/Iteration | Iterations | Total Time |\n"
    table_separator = "|------|-----|-----------|----------------|------------|------------|\n"
    cold_row        = format_table_row("COLD", cold_result)
    warm_row        = format_table_row("WARM", warm_result)

    combined_result = table_header + table_separator + cold_row + warm_row + "\n"

    File.open(benchmark_file(path), "a") { |f| f.write(timestamp_header + combined_result) }

    puts "✅ Results saved to #{benchmark_file(path)}"
  end

  private

    def setup_benchmark_env(path)
      ENV["USE_AUTH"]      = "true"
      ENV["USE_SERVER"]    = "puma"
      ENV["PATH_TO_HIT"]   = path
      ENV["HTTP_METHOD"]   = "GET"
      ENV["RAILS_LOG_LEVEL"] ||= "info" # keep output clean
    end

    def benchmark_file(path)
      filename = case path
      when "/" then "dashboard"
      else
        path.gsub("/", "_").gsub(/^_+/, "")
      end
      "tmp/benchmarks/#{filename}.txt"
    end

    def extract_clean_results(output)
      lines = output.split("\n")

      # Example benchmark-ips output line:
      # "         SomeLabel    14.416k (± 3.8%) i/s -     72.000k in   5.004618s"
      result_line = lines.find { |line| line.match(/\d[\d\.kM]*\s+\(±\s*[0-9\.]+%\)\s+i\/s/) }

      if result_line
        if (match = result_line.match(/(\d[\d\.kM]*)\s+\(±\s*([0-9\.]+)%\)\s+i\/s\s+(?:\(([^)]+)\)\s+)?-\s+(\d[\d\.kM]*)\s+in\s+(\d+\.\d+)s/))
          ips_value          = match[1]
          deviation_percent  = match[2].to_f
          time_per_iteration = match[3] || "-"
          iterations         = match[4]
          total_time         = "#{match[5]}s"

          {
            ips:                ips_value,
            deviation:          "± %.2f%%" % deviation_percent,
            time_per_iteration: time_per_iteration,
            iterations:         iterations,
            total_time:         total_time
          }
        else
          no_data_hash
        end
      else
        no_data_hash("No results")
      end
    end

    def format_table_row(type, data)
      # Wider deviation column accommodates strings like "± 0.12%"
      "| %-4s | %-5s | %-11s | %-14s | %-10s | %-10s |\n" % [
        type,
        data[:ips],
        data[:deviation],
        data[:time_per_iteration],
        data[:iterations],
        data[:total_time]
      ]
    end

    def no_data_hash(ips_msg = "No data")
      {
        ips:                ips_msg,
        deviation:          "-",
        time_per_iteration: "-",
        iterations:         "-",
        total_time:         "-"
      }
    end
end
