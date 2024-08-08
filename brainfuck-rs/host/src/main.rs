use powdr::backend::BackendType;
use powdr::riscv::continuations::bootloader::default_input;
use powdr::riscv::{compile_rust, Runtime};
use powdr::GoldilocksField;
use powdr::Pipeline;

use std::fs;
use std::path::PathBuf;
use std::time::Instant;

use clap::Parser;

#[derive(Parser)]
struct Options {
    #[clap(short, long, required = true)]
    program: PathBuf,

    #[clap(short, long)]
    inputs: Option<PathBuf>,

    #[clap(short, long)]
    execute: bool,

    #[clap(short, long, default_value = ".")]
    output: PathBuf,

    #[clap(short, long)]
    fast_tracer: bool,

    #[clap(short, long)]
    witgen: bool,

    #[clap(long)]
    proof: bool,
}

fn read_file_and_convert(path: PathBuf) -> Vec<u32> {
    let content = fs::read_to_string(path).unwrap();
    content.bytes().map(|b| b as u32).collect()
}

type F = GoldilocksField;

fn main() {
    let mut options = Options::parse();
    if options.proof {
        options.witgen = true;
    }

    env_logger::init();

    let mut program = read_file_and_convert(options.program);
    program.push(0);

    let inputs = match options.inputs {
        Some(inputs) => read_file_and_convert(inputs),
        None => vec![],
    };

    if options.execute {
        log::info!("Running native brainfuck interpreter...");
        let output =
            String::from_utf8(brainfuck_interpreter::run(program.clone(), inputs.clone())).unwrap();
        println!("{output}");
    }

    if !(options.fast_tracer || options.witgen) {
        return;
    }

    log::info!("Compiling powdr-brainfuck...");
    let (asm_file_path, asm_contents) = compile_rust::<F>(
        "./powdr-guest",
        &options.output,
        true,
        &Runtime::base(),
        true,
        false,
    )
    .ok_or_else(|| vec!["could not compile rust".to_string()])
    .unwrap();

    log::debug!("powdr-asm code:\n{asm_contents}");

    // Create a pipeline from the asm program
    let mut pipeline = Pipeline::<F>::default()
        .from_asm_string(asm_contents.clone(), Some(asm_file_path.clone()))
        .with_output(options.output.clone(), true)
        .add_data(2, &inputs)
        .add_data(1, &program);

    if options.fast_tracer {
        log::info!("Running powdr-riscv executor in fast mode...");
        let start = Instant::now();

        let program = pipeline.compute_analyzed_asm().unwrap().clone();
        let initial_memory = powdr::riscv::continuations::load_initial_memory(&program);
        let (trace, _mem, _reg_mem) = powdr::riscv_executor::execute_ast::<F>(
            &program,
            initial_memory,
            pipeline.data_callback().unwrap(),
            &default_input(&[]),
            usize::MAX,
            powdr::riscv_executor::ExecMode::Fast,
            None,
        );

        let duration = start.elapsed();
        log::info!("Fast executor took: {:?}", duration);
        log::info!("Trace length: {}", trace.len);
    }

    if options.witgen {
        log::info!("Running witness generation...");
        let start = Instant::now();

        pipeline.compute_witness().unwrap();

        let duration = start.elapsed();
        log::info!("Witness generation took: {:?}", duration);
    }

    if options.proof {
        let mut pipeline = pipeline.with_backend(BackendType::Plonky3Composite, None);
        log::info!("Computing proof...");
        let start = Instant::now();

        pipeline.compute_proof().unwrap();

        let duration = start.elapsed();
        log::info!("Proof generation took: {:?}", duration);
    }

    log::info!("Done.");
}
