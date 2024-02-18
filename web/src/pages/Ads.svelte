<script lang="ts">
	import { Config } from '../../config';
	import type { IAd } from '../interfaces/IAd';

	export let ads: Array<IAd>;
</script>

<div class="ads-container">
	<div class="ads newspaper-left-page pa-5">
		<h4>{Config.text.ads.title}</h4>
		{#each ads as ad}
			<div class="mb-10 ad">
				<h6>{ad.name} ({ad.date})</h6>
				<p>{ad.message}</p>
			</div>
		{/each}
	</div>
</div>

<style lang="scss">
	.ads-container {
		display: flex;
		flex: 1;
		justify-content: space-between;
		height: 900px;

		.ads {
			width: 80%;
			flex: 1;
		}

		.ad {
			border-top: 1px rgba(0, 0, 0, 0.6) solid;
			border-bottom: 1px rgba(0, 0, 0, 0.6) solid;
		}

		div {
			flex-grow: 1;
		}
	}
</style>
