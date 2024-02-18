import type { ISentence } from './ISentence';
import type { IAd } from './IAd';
import type { Story } from './story';

export interface INewspaperData {
	stories: Array<Story>;
	sentences: Array<ISentence>;
	ads: Array<IAd>;
	jailSentences: Array<any>;
	reporterLevel: number;
	reporterOnDuty: boolean;
	isReporter: boolean;
	playerName: string;
}
