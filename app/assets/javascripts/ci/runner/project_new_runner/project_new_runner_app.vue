<script>
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import RunnerCreateForm from '~/ci/runner/components/runner_create_form.vue';
import { PROJECT_TYPE } from '../constants';
import { saveAlertToLocalStorage } from '../local_storage_alert/save_alert_to_local_storage';

export default {
  name: 'ProjectNewRunnerApp',
  components: {
    RunnerCreateForm,
    PageHeading,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    projectId: {
      type: String,
      required: true,
    },
  },
  methods: {
    onSaved(runner) {
      this.trackEvent('click_create_project_runner_button');

      saveAlertToLocalStorage({
        message: s__('Runners|Runner created.'),
        variant: VARIANT_SUCCESS,
      });
      visitUrl(runner.ephemeralRegisterUrl);
    },
    onError(error) {
      createAlert({ message: error.message });
    },
  },
  PROJECT_TYPE,
};
</script>

<template>
  <div>
    <page-heading :heading="s__('Runners|Create project runner')">
      <template #description>
        {{
          s__(
            'Runners|Create a project runner to generate a command that registers the runner with all its configurations.',
          )
        }}
      </template>
    </page-heading>

    <runner-create-form
      :runner-type="$options.PROJECT_TYPE"
      :project-id="projectId"
      @saved="onSaved"
      @error="onError"
    />
  </div>
</template>
