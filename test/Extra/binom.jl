using Distributions, StanSample, Test

binom_model = "
data{
    int W;
    int F[W];
    int R[W];
}
parameters{
    real<lower=0,upper=1> a;
    real<lower=0> theta;
}
model{
    vector[W] pbar;
    theta ~ exponential( 3 );
    a ~ beta( 3 , 7 );
    R ~ beta_binomial(F ,  a * theta, (1 - a) * theta );
}
generated quantities{
    vector[W] log_lik;
    vector[W] y_hat;
    for ( i in 1:W ) {
        log_lik[i] = beta_binomial_lpmf( R[i] | F[i] , a * theta, (1 - a) * theta  );
        y_hat[i] = beta_binomial_rng(F[i] , a * theta, (1 - a) * theta );
    }
}
"

sm = SampleModel("binomial", binom_model)

probs = rand(Beta(0.3 * 40, 0.7 * 40), 300)
trials = [450 for i = 1:300]
res = [rand(Binomial(trials[i], probs[i]), 1)[1] for i in 1:300]

#d <- list(W = 300, F = trials, R = res)
binom_data = Dict("W" => 300, "F" => trials, "R" => res)

rc = stan_sample(sm, data=binom_data)

if success(rc)
  chn = read_samples(sm)
  show(chn)
  
  # Create a ChainDataFrame
  df = read_summary(sm)
  @test df[df.parameters .== :theta, :mean][1] ≈ 0.24 rtol=0.1
  
end