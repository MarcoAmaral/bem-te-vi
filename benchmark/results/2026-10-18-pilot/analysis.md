### Per condition (pilot)

| Condition | n | Content pass | 95% CI (exact) | Contract pass | 95% CI (exact) | Content score | Judge pass | Mean cost per generation, judge included (US$) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A | 9 | 3/9 (33.3%) | 7.5% to 70.1% | 0/9 (0.0%) | 0.0% to 33.6% | 77.0% | 2/3 | 0.0277 |
| B | 9 | 4/9 (44.4%) | 13.7% to 78.8% | 0/9 (0.0%) | 0.0% to 33.6% | 86.3% | 1/3 | 0.0308 |
| C | 9 | 2/9 (22.2%) | 2.8% to 60.0% | 0/9 (0.0%) | 0.0% to 33.6% | 74.6% | 1/3 | 0.0355 |
| D | 9 | 8/9 (88.9%) | 51.8% to 99.7% | 7/9 (77.8%) | 40.0% to 97.2% | 96.3% | 3/3 | 0.0491 |

### Content pass by task (pilot)

| Task | A | B | C | D |
| --- | --- | --- | --- | --- |
| a11y-signup-form | 0/1 | 0/1 | 0/1 | 1/1 |
| api-orders-contract | 1/1 | 1/1 | 1/1 | 1/1 |
| bdd-loyalty-points | 0/1 | 0/1 | 0/1 | 1/1 |
| cases-order-status | 1/1 | 1/1 | 0/1 | 0/1 |
| cases-quantity | 0/1 | 1/1 | 0/1 | 1/1 |
| cases-shipping-fee | 0/1 | 0/1 | 0/1 | 1/1 |
| defect-gift-card | 0/1 | 0/1 | 0/1 | 1/1 |
| flaky-run-history | 1/1 | 1/1 | 1/1 | 1/1 |
| plan-split-payment | 0/1 | 0/1 | 0/1 | 1/1 |

### Contrasts on content pass (pilot)

| Contrast | Difference (points) | 98.33% bootstrap interval | Tasks | Smallest cell | Reading |
| --- | --- | --- | --- | --- | --- |
| D vs C | +66.7 | +66.7 to +66.7 | 9 | 1 | underpowered, no conclusion |
| D vs B | +44.4 | +44.4 to +44.4 | 9 | 1 | underpowered, no conclusion |
| D vs A | +55.6 | +55.6 to +55.6 | 9 | 1 | underpowered, no conclusion |

Content pass: every `con-` grader of the task passed. Intervals per condition are exact (Clopper-Pearson); contrasts average the per-task difference with equal task weight, bootstrap 10000 replicates resampling runs within each task and condition, seed 20261018, Bonferroni over 3 contrasts. A contrast is read only when every cell holds at least 8 generations.
