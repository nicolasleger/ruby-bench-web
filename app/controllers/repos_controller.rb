class ReposController < ApplicationController
  def show
    organization = find_organization_by_name(params[:organization_name])
    @repo = find_organization_repos_by_name(organization, params[:repo_name])
    @form_result_types = sort_form_result_types(params[:result_types])
    benchmark_runs = fetch_benchmark_runs(@repo.commits, 'Commit')
    @result_types = fetch_benchmark_runs_categories(benchmark_runs)

    chart_builder = ChartBuilder.new(
      benchmark_runs.where(category: @form_result_types)
    )

    @chart_columns = chart_builder.build_columns do |benchmark_run|
      "
        Commit: #{benchmark_run.initiator.sha1[0..6]}<br>
        Commit Date: #{benchmark_run.initiator.created_at}<br>
        Environment: #{benchmark_run.environment}
      ".squish
    end
  end

  def show_releases
    organization = find_organization_by_name(params[:organization_name])
    @repo = find_organization_repos_by_name(organization, params[:repo_name])
    releases = @repo.releases
    @form_result_types = sort_form_result_types(params[:result_types])
    benchmark_runs = fetch_benchmark_runs(releases, 'Release')
    @result_types = fetch_benchmark_runs_categories(benchmark_runs)
    chart_categories ||= ['Ruby Version']

    chart_builder = ChartBuilder.new(
      benchmark_runs.where(category: @form_result_types)
    )

    @chart_columns = chart_builder.build_columns do |benchmark_run|
      benchmark_run.initiator.version
    end
  end

  private

  def find_organization_by_name(name)
    Organization.find_by_name(params[:organization_name]) || not_found
  end

  def find_organization_repos_by_name(organization, name)
    organization.repos.find_by_name(name)
  end

  def sort_form_result_types(result_types)
    result_types.try(:sort)
  end

  def fetch_benchmark_runs(initiators, initiator_type)
    BenchmarkRun.where(
      initiator_id: initiators.map(&:id),
      initiator_type: initiator_type
    ).preload(:initiator)
  end

  def fetch_benchmark_runs_categories(benchmark_runs)
    benchmark_runs.pluck(:category).uniq.sort.group_by do |category|
      category =~ /\A([^_]+)_/
      $1
    end
  end
end
