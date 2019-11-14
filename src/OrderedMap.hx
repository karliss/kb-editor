package;

import haxe.ds.BalancedTree;

class OrderedMap<K, V> extends BalancedTree<K, V> {
	var compareFunc:(K, K) -> Int;

	public function new(compareFunc:(K, K) -> Int) {
		super();
		this.compareFunc = compareFunc;
	}

	override function compare(k1:K, k2:K):Int {
		return compareFunc(k1, k2);
	}
}
