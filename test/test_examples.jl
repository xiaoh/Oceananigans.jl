const EXAMPLES_DIR = "../examples/"

function run_example(replace_strings, example_name, module_suffix="")
    example_filepath = joinpath(EXAMPLES_DIR, example_name * ".jl")
    file_content = read(example_filepath, String)

    for strs in replace_strings
        file_content = replace(file_content, strs[1] => strs[2])
    end

    test_script_filepath = example_name * "_example_test.jl"

    open(test_script_filepath, "w") do f
        write(f, "module Test_$example_name" * "_$module_suffix\n")
        write(f, file_content)
        write(f, "\nend # module")
    end

    try
        include(test_script_filepath)
    catch err
        # Throw the error
        @error sprint(showerror, err)

        # Print the content of the file to the test log, with line numbers, for debugging
        delineated_file_content = split(file_content, '\n')

        @printf "% 3d module Test_%s_%s\n" 1 example_name module_suffix

        for (number, line) in enumerate(delineated_file_content)
            @printf "% 3d %s\n" number line
        end

        @printf("% 3d end # module", number+2)

        # Delete the test script
        rm(test_script_filepath)

        return false
    end

    # Delete the test script (if it hasn't been deleted already)
    rm(test_script_filepath)

    return true
end

@testset "Examples" begin
    @info "Testing examples..."

    @testset "One-dimensional diffusion" begin
        @info "  Testing one-dimensional diffusion example"

        replace_strings = [
            ("size = (1, 1, 128)", "size = (1, 1, 16)"),
            ("stop_iteration = 1000", "stop_iteration = 1"),
            ("stop_iteration += 100", "stop_iteration += 1"),
            ("for i=1:100", "for i=1:1"),
            ("mp4(", "# mp4(")
        ]

        @test run_example(replace_strings, "one_dimensional_diffusion")
    end

    @testset "Two-dimensional turbulence example" begin
        @info "  Testing two-dimensional turbulence example"

        replace_strings = [
            ("N=(128, 128, 1)", "N=(16, 16, 1)"),
            ("for i=1:100", "for i=1:1"),
            ("stop_iteration += 10", "stop_iteration += 1"),
            ("mp4(", "# mp4(")
        ]

        @test run_example(replace_strings, "two_dimensional_turbulence")
    end

    for arch in archs
        @testset "Wind and convection-driven mixing example [$(typeof(arch))]" begin
            @info "  Testing wind and convection-driven mixing example [$(typeof(arch))]"

            replace_strings = [
                ("Nz = 32", "Nz = 16"),
                ("progress_frequency=10", "progress_frequency=1"),
                ("for i in 1:100", "for i in 1:1"),
                ("stop_iteration += 10", "stop_iteration += 1"),
                ("mp4(", "# mp4(")
            ]

            if arch == GPU()
                push!(replace_strings, ("architecture = CPU()", "architecture = GPU()"))
            end

            @test run_example(replace_strings, "ocean_wind_mixing_and_convection", string(typeof(arch)))

            rm("ocean_wind_mixing_and_convection.jld2", force=true)
        end
    end

    @testset "Ocean convection with plankton example" begin
        @info "  Testing ocean convection with plankton example"

        replace_strings = [
            ("Nz = 128", "Nz = 16"),
            ("progress_frequency=100", "progress_frequency=1"),
            ("for i = 1:100", "for i = 1:1"),
            ("stop_iteration += 100", "stop_iteration += 1"),
            ("mp4(", "# mp4(")
        ]

        @test run_example(replace_strings, "ocean_convection_with_plankton")
    end

    @testset "Internal wave example" begin
        @info "  Testing internal wave example"

        replace_strings = [
            ("Nx = 128", "Nx = 16"),
            ("progress_frequency = 20", "progress_frequency = 1"),
            ("for i=1:100", "for i=1:1"),
            ("stop_iteration += 20", "stop_iteration += 1"),
            ("mp4(", "# mp4(")
        ]

        @test run_example(replace_strings, "internal_wave")
    end

    @testset "Eady turbulence" begin
        @info "  Testing Eady turbulence example"

        replace_strings = [
            ("Nh = 64", "Nh = 16"),
            ("Nz = 32", "Nz = 16"),
            ("end_time = 3day", "end_time = 1"),
            # Get rid of anything PyPlot/PyCall related
            ("using PyPlot, PyCall", ""),
            ("GridSpec =", "#"),
            ("fig =", "#"),
            ("gs =", "#"),
            ("fig.add_subplot", "#"),
            ("gcf()", "#"),
            ("makeplot!", "#makeplot!"),
            ("function #makeplot!(axs, model)", "function makeplot!(axs, model)")
        ]

        @test run_example(replace_strings, "eady_turbulence")
    end
end
