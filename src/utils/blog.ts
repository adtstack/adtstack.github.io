import type { CollectionEntry } from 'astro:content';

export function newestFirst(a: CollectionEntry<'blog'>, b: CollectionEntry<'blog'>) {
	return b.data.pubDate.valueOf() - a.data.pubDate.valueOf() ||
		b.id.localeCompare(a.id, 'en', { numeric: true });
}

export function tagUrl(tag: string) {
	return `/blog/tags/${encodeURIComponent(tag)}/`;
}
